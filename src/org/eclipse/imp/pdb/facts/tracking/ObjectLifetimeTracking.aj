package org.eclipse.imp.pdb.facts.tracking;

import java.io.BufferedOutputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.ref.WeakReference;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.WeakHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.logging.Logger;
import java.util.zip.GZIPOutputStream;

import nl.cwi.swat.BCITracker;

import org.aspectj.lang.JoinPoint;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.impl.primitive.BoolValue;
import org.eclipse.imp.pdb.facts.io.hash.HashWriter;

import com.google.common.base.Predicate;
import com.google.common.base.Predicates;

public aspect ObjectLifetimeTracking {

	static Logger logger = Logger.getLogger(ObjectLifetimeTracking.class.getName());

	static final boolean useStrongObjectPool = System.getProperties().containsKey("strongObjectPool");
	
	public static enum MemoryMeasurementMode {
		COUNT_AS_ONE,
		DEEP_COUNT,
		DIFF_COUNT
	}
	
	static final MemoryMeasurementMode memoryMeasurementMode = MemoryMeasurementMode.DIFF_COUNT;
	
	static {
//		logger.setUseParentHandlers(false);
	
		if (useStrongObjectPool) {
			objectPool = new HashMap<>();
		} else {
			objectPool = new WeakHashMap<>();
		}
	}

	static boolean isRedundancyProfilingEnabled = System.getProperties().containsKey(
					"redundancyProfilingEnabled");
	
	static boolean isSharingEnabled = System.getProperties().containsKey("sharingEnabled");

	final static protected boolean isOrderUnorderedDisabled = System.getProperties().containsKey("orderUnorderedDisabled");
	
	public static enum TrackingMode {
		PROFILE_HASH_SIG,
		PROFILE_FULL_SIG, // equals TrackingMode.SAMPLE && SAMPLE_FREQUENCY == 1;
		SAMPLE
	}
	
	static TrackingMode trackingMode = TrackingMode.PROFILE_HASH_SIG;
	
	static int SAMPLE_ALLOCATION_COUNT = 0; 
	static final int SAMPLE_FREQUENCY  = 2;
	
	static WeakIdentityHashMap<Object, Object> referencedByIValue = new WeakIdentityHashMap<>();

	static HashWriter hashWriter = new HashWriter();
		
	
	volatile boolean doLog = true;

	static final boolean logCacheBehavior = false;
	static final boolean logRootEqualsSummary = false;
	
	static final boolean logEqualsCallInsideAdvice = false;
	static final boolean logEqualsCallInInsideAdvice = false;
	
	static final boolean logEqualsCallOutsideAdvice = false;
	static final boolean logEqualsCallInOutsideAdvice = false;

	static final boolean logIsEqualCallOutsideAdvice = false;
	static final boolean logIsEqualCallInOutsideAdvice = false;
	
	static long cacheHitCount = 0;	
	static long cacheMissCount = 0;
	static long cacheRaceCount = 0;
	
	
	public static enum EqualsOnAliasMode {
		EMIT_WARNING,
		COUNT_AS_REFERENCE_EQUALITY
	}
	
	static final EqualsOnAliasMode equalsOnAliasMode = EqualsOnAliasMode.COUNT_AS_REFERENCE_EQUALITY;
	static final boolean recordHashCollisions = false;
	
	static OutputStream outputStream;
	static OutputStream equalsRelationOutputStream;
	static OutputStream tagMapOutputStream;
	
	final static int BUF_SIZE = 16777216; 
	
	ObjectLifetimeTracking() throws Exception {
		System.out.println("Orpheus hijacked Rascal.");
		
		outputStream = new BufferedOutputStream(new GZIPOutputStream(new FileOutputStream("target/_allocation_relation.bin.gz")), BUF_SIZE);
		equalsRelationOutputStream = new BufferedOutputStream(new GZIPOutputStream(new FileOutputStream("target/_equals_relation.bin.gz")), BUF_SIZE);
		tagMapOutputStream = new BufferedOutputStream(new GZIPOutputStream(new FileOutputStream("target/_tag_map.bin.gz")), BUF_SIZE);
		
		// flush collected data to disk.
		Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
			@Override
			public void run() {				
				doLog = false;
				
				try {
					outputStream.close();
					equalsRelationOutputStream.close();
					tagMapOutputStream.close();
				} catch (Exception e) {
					e.printStackTrace();
				}
				
				Path writeFile = Paths.get("target", "_hashAndCacheStatistic.bin.txt");
				try {
					Files.write(writeFile, Arrays.asList(
							"Hash Collisions: " + hashTableCollision,
							"Hash Collisions Same Reference: " + hashTableSameReferenceCollision,
							"Cache Hit:  " + cacheHitCount,
							"Cache Miss: " + cacheMissCount,
							"Cache Race: " + cacheRaceCount,
							"Last Count: " + BCITracker.getCount()), Charset.forName("UTF-8"));
				} catch (IOException e) {
					e.printStackTrace();
				}
				
				System.out.println("Hash Collisions: " + hashTableCollision);
				System.out.println("Hash Collisions Same Reference: " + hashTableSameReferenceCollision);
				System.out.println();
				System.out.println("Cache Hit:  " + cacheHitCount);
				System.out.println("Cache Miss: " + cacheMissCount);
				System.out.println("Cache Race: " + cacheRaceCount);
				System.out.println("Last Count: " + BCITracker.getCount());
				
				/*
				 * Clean up referenced values to have more heap space for
				 * serializing data.
				 */
				referencedByIValue = null;
				System.gc();
			}
		}));
		
		if (isRedundancyProfilingEnabled) {
			trackNewObjectUnconditionally(null, BoolValue.TRUE, null,
							BCITracker.getAndIncrementCount(), false);
			trackNewObjectUnconditionally(null, BoolValue.FALSE, null,
							BCITracker.getAndIncrementCount(), false);
			logger.info("Boolean constants are not in the object pool.");
		}
	}
	
	/**
	 * The difference between execution and call is outlined at:
	 * http://eclipse.org/aspectj/doc/released/faq.php#q:comparecallandexecution
	 * 
	 * Call pointcuts are herein the preferred way, because we control the whole source at compile time,
	 * whereas otherwise we would have to fall back to execution pointcuts.
	 * 
	 * With the call pointcut, we don not have to rely upon factory for each IValue implementation.
	 */
//	pointcut allocationWithFactory() : execution(static IValue+ *.new*(..)) && !execution(static IValue+ *.newBool*(..));
	pointcut allocationWithConstructor() : 
		(
				if(isRedundancyProfilingEnabled || isSharingEnabled)
				&& call(org.eclipse.imp.pdb.facts.IValue+.new(..)) 
				&& !call(org.eclipse.imp.pdb.facts.IExternalValue+.new(..))
				&& !call(org.eclipse.imp.pdb.facts.impl.primitive.BoolValue.*.new(..))
				&& !call(org.rascalmpl.interpreter.result.ICallableValue+.new(..))
		);
	
//	Object around() : allocationWithFactory() {
	Object around() : allocationWithConstructor() {
		final Object newObject = proceed();
		
		if (isRedundancyProfilingEnabled && isSharingEnabled) {
			final long eventTimestamp = BCITracker.getAndIncrementCount();
			
			WeakReference<Object> poolObjectReferene = getFromObjectPool(newObject);
			
			if (poolObjectReferene == null) {
				cacheMissCount++;
				if (logCacheBehavior) {
					logger.fine("CACHE MISS");
					logObjectDetails(newObject);
				}
				
				putIntoObjectPool(newObject);
				trackNewObject(thisEnclosingJoinPointStaticPart, newObject, null, eventTimestamp, false);
				return newObject;
			} else {
				Object weaklyReferencedObject = poolObjectReferene.get();
				
				if (weaklyReferencedObject != null) {
					cacheHitCount++;
					if (logCacheBehavior) {
						logger.fine("CACHE HIT");
						logObjectDetails(newObject);
					}
					
					/*
					 * Still track short living object that will get discarded.
					 */
					trackNewObject(thisEnclosingJoinPointStaticPart, newObject, weaklyReferencedObject, eventTimestamp, true);
					return weaklyReferencedObject;
				} else {
					cacheRaceCount++;
					if (logCacheBehavior) {
						logger.fine("CACHE RACE");
						logObjectDetails(newObject);
					}

					trackNewObject(thisEnclosingJoinPointStaticPart, newObject, null, eventTimestamp, false);
					return newObject;
				}
			}	
		} else if (isRedundancyProfilingEnabled) {
			final long eventTimestamp = BCITracker.getAndIncrementCount();
			
			trackNewObject(thisEnclosingJoinPointStaticPart, newObject, null, eventTimestamp, false);
			return newObject;			
		} else if (isSharingEnabled) {
			// the same as the first if-statement but without trackNewObject(..) calls.
			WeakReference<Object> poolObjectReferene = getFromObjectPool(newObject);
			
			if (poolObjectReferene == null) {
				cacheMissCount++;
				if (logCacheBehavior) {
					logger.fine("CACHE MISS");
					logObjectDetails(newObject);
				}
				
				putIntoObjectPool(newObject);
				return newObject;
			} else {
				Object weaklyReferencedObject = poolObjectReferene.get();
				
				if (weaklyReferencedObject != null) {
					cacheHitCount++;
					if (logCacheBehavior) {
						logger.fine("CACHE HIT");
						logObjectDetails(newObject);
					}
					
					return weaklyReferencedObject;
				} else {
					cacheRaceCount++;
					if (logCacheBehavior) {
						logger.fine("CACHE RACE");
						logObjectDetails(newObject);
					}
					
					return newObject;
				}
			}			
		} else {
			return newObject;
		}
	}

	static void logObjectDetails(Object v1) {
		// NOTE: Cached hashes are not yet calculated here, thus it would fail.
//		byte[] h1 = hashWriter.calculateHash((IValue) v1);
		
		logger.finest(String.format("OBJ_[CLASS CMP] %s", v1.getClass().getCanonicalName()));
//		logger.finest(String.format("OBJ_[HASH  CMP] %s", toHexString(h1));
		logger.finest(String.format("OBJ_[VALUE CMP] %s", v1));
		logger.finest(String.format("OBJ_[HASHC CMP] %d", v1.hashCode()));
		logger.finest(String.format("OBJ_[ ID   CMP] %d", System.identityHashCode(v1)));	
		logger.finest(String.format("OBJ_[TAGS  CMP] %d", BCITracker.getTag(v1)));
	}	
	
	WeakReference<Object> getFromObjectPool(Object prototype) {
		return objectPool.get(prototype);
	}
	
	void putIntoObjectPool(Object prototype) {
		objectPool.put(prototype, new WeakReference<>(prototype));
	}	
	
	void trackNewObjectUnconditionally(JoinPoint.StaticPart sjp, final Object newObject, final Object oldObject, final long eventTimestamp, final boolean isRedundant) {
		if (doLog) {		
			BCITracker.setTag(newObject, eventTimestamp);
			
			final TrackingProtocolBuffers.ObjectLifetime.Builder allocationRecBldr = 
					TrackingProtocolBuffers.ObjectLifetime.newBuilder()
						.setTag(eventTimestamp)
						.setIsRedundant(isRedundant && !isOrderUnorderedDisabled)
						.setCtorTime(eventTimestamp);
			
			final TrackingProtocolBuffers.TagMap.Builder tagInfoBldr = 
					TrackingProtocolBuffers.TagMap.newBuilder()
						.setTag(eventTimestamp);
			
			/*
			 * Digest Calculation (Expensive)
			 */
			final Runnable digestCalculationTask = new Runnable() {
				@Override
				public void run() {
					byte[] digest = new byte[] {};
					
					if (isRedundant && !isOrderUnorderedDisabled) {
						// lookup hash for old object
						digest = hashWriter.calculateHash((IValue) oldObject);
					} else {
						// calculate hash for new object
						switch (trackingMode) {
						case PROFILE_HASH_SIG:
							// hash calculation based on hashes of contained elements
							digest = hashWriter.calculateHash((IValue) newObject);
							break;
							
						case PROFILE_FULL_SIG:
						case SAMPLE:
							// hashes full composite object
							digest = HashWriter.toHashByteArray((IValue) newObject);
							break;
						}						
					}
//					tagInfoBldr.setDigest(toHexString(digest));
					allocationRecBldr.setDigest(toHexString(digest));
				}
			};

			/*		
			 * Measure Additional Memory Consumption (Expensive and Memory Intensive)
			 */
			final Runnable memoryCalculationTask = new Runnable() {
				@Override
				public void run() {
					allocationRecBldr.setMeasuredSizeInBytes(measureObjectSize(newObject));					
				}
			};
			
			/*
			 * Execute task and block until result is ready.
			 */
			if (isSharingEnabled) {
				memoryCalculationTask.run();	
			} else {
				digestCalculationTask.run();
				memoryCalculationTask.run();
				
				allocationRecBldr.setRecursiveReferenceEqualitiesEstimate(
						hashWriter.estimateReferenceEqualities((IValue) newObject));
			}				
				
			// Serialize to file 
			try {
				// Allocation record
				allocationRecBldr
					.build()
					.writeDelimitedTo(outputStream);

				// [print] the object
//				System.out.println(newObject);
				
				// [print] Allocation record
//				System.out.println(allocationRecBldr.build().toString());							
				
				// Tag related data
				
//				if (!isSharingEnabled) {
//					tagInfoBldr
//						.build()
//						.writeDelimitedTo(tagMapOutputStream);
//				}	
				
				// [print] Tag related data
//				System.out.println(tagInfoBldr.build().toString());				
			} catch (Exception e) {
				e.printStackTrace();
			}	
		}	
	}	
	
	void trackNewObject(JoinPoint.StaticPart sjp, final Object newObject, final Object oldObject, final long eventTimestamp, final boolean isRedundant) {
		SAMPLE_ALLOCATION_COUNT++;
		
		if (trackingMode == TrackingMode.PROFILE_FULL_SIG || trackingMode == TrackingMode.PROFILE_HASH_SIG || 
				(trackingMode == TrackingMode.SAMPLE && SAMPLE_ALLOCATION_COUNT % SAMPLE_FREQUENCY == 0)) {		
			trackNewObjectUnconditionally(sjp, newObject, oldObject, eventTimestamp, isRedundant);
		}
	}	
	
	long measureObjectSize(final Object reference) {		
		switch (memoryMeasurementMode) {
		case DIFF_COUNT: {
			Predicate<Object> isRoot = new Predicate<Object>() {
				@Override
				public boolean apply(Object arg0) {
					return arg0 == reference;
				}
			};
			
			Predicate<Object> isUnseen = new Predicate<Object>() {
				@Override
				public boolean apply(Object arg0) {				
					if (referencedByIValue.containsKey(arg0)) {
						return false;
					} else {
						referencedByIValue.put(arg0, null);
						return true;
					}
				}
			};
			
			Predicate<Object> jointPredicate = Predicates.or(
					isRoot,
					Predicates.and(						
							Predicates.not(Predicates.instanceOf(IValue.class)), 
							isUnseen
							)
					);
			
			return objectexplorer.MemoryMeasurer.measureBytes(reference, jointPredicate);		

		} case DEEP_COUNT: {
			Predicate<Object> isRoot = new Predicate<Object>() {
				@Override
				public boolean apply(Object arg0) {
					return arg0 == reference;
				}
			};
			
			Predicate<Object> jointPredicate = Predicates.or(
					isRoot,
					Predicates.not(Predicates.instanceOf(IValue.class)));
			
			return objectexplorer.MemoryMeasurer.measureBytes(reference, jointPredicate);
		
		} case COUNT_AS_ONE: {
			return 1;
			
		} default: {
			throw new RuntimeException("Unsupported mode.");	
		}
		}
	}
		
	protected static String toHexString(byte[] bytes) {
		char[] hexChars = toHexCharArray(bytes);
		return new String(hexChars);
	}	
	
	/**
	 * Converts a byte array into a hex string with leading zeros.
	 * 
	 * For a discussion about the implementation see: 
	 * http://stackoverflow.com/questions/332079/in-java-how-do-i-convert-a-byte-array-to-a-string-of-hex-digits-while-keeping-l
	 * 
	 * @param bytes an input byte array
	 * @return hex string with capital letters
	 */
	protected static char[] toHexCharArray(byte[] bytes) {
		char[] hexArray = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
				'A', 'B', 'C', 'D', 'E', 'F' };
		char[] hexChars = new char[bytes.length * 2];
		
		int charPairAsInt;
		for (int i = 0; i < bytes.length; i++) {
			charPairAsInt = bytes[i] & 0xFF;
			hexChars[i * 2]     = hexArray[charPairAsInt / 16]; // first  character
			hexChars[i * 2 + 1] = hexArray[charPairAsInt % 16]; // second character
		}
		return hexChars;
	}	

	
	/**
	 * Applying fixed hash code.
	 */
	pointcut hashCodeInsideAdvice() : 
		if(isSharingEnabled) 
			&& cflow(allocationWithConstructor()) 
			&& execution(int org.eclipse.imp.pdb.facts.impl.Annotated*Facade.hashCode());
	
	int around(IValue v1) : hashCodeInsideAdvice() && target(v1) {
		return v1.fixedHashCode();
	}
	
	/**
	 * Object pool that is used in maximum sharing mode.
	 */
	final static Map<Object, WeakReference<Object>> objectPool;
	static long hashTableCollision = 0;
	static long hashTableSameReferenceCollision = 0;
	
	/*
	 * equals(..) call tracking in aspect
	 */				
	public static aspect InnerEqualsInstanceTracker percflow(topEqualsInsideAdvice() && scopedPoolLookup()) {
		
		long innerEqualsID = equalityIDCounter.getAndIncrement();
		
		int deepEqualsCount = 1;
		int deepReferenceEqualityCount = 0;
		
//		boolean firstEntrance = true;

		pointcut scopedPoolLookup() : cflowbelow(call(* ObjectLifetimeTracking.*ObjectPool(..)));
		
		pointcut equalsInsideAdvice() : ( 
				execution(boolean org.eclipse.imp.pdb.facts.IValue+.equals(..)) 
				&& !execution(boolean org.eclipse.imp.pdb.facts.IExternalValue+.equals(..))
				&& !execution(boolean org.rascalmpl.interpreter.result.ICallableValue+.equals(..))
			);

		pointcut topEqualsInsideAdvice() : if(isRedundancyProfilingEnabled) && cflow(adviceexecution()) && equalsInsideAdvice() && !cflowbelow(equalsInsideAdvice());
		
		pointcut lowerEqualsCallInsideAdvice() : cflowbelow(equalsInsideAdvice()) && ( 
				execution(boolean org.eclipse.imp.pdb.facts.IValue+.equals(..)) 
				&& !execution(boolean org.eclipse.imp.pdb.facts.IExternalValue+.equals(..))
				&& !execution(boolean org.rascalmpl.interpreter.result.ICallableValue+.equals(..))
			);
		
		boolean around(Object v1, Object v2) : topEqualsInsideAdvice() && target(v1) && args(v2) {		
			/*
			 * TODO: top level equals not precise enough.
			 * Fails on RationalValue:344 hashCode(..), because equals(..) is called in hashCode(..)
			 */
//			if (v1 == v2) throw new RuntimeException("Equals with aliased value: " + v1.toString());
			
			long timestamp = BCITracker.getCount();	
			
//			if (firstEntrance) {
//				logger.info(innerEqualsID + " First.");
//				firstEntrance = false;
//			} else {
//				logger.info(innerEqualsID + " Not first!");
//			}
			
			// Bottom-up printing
			if (logEqualsCallInsideAdvice) {
				logger.finest("[equalsCallInsideAdvice]");
				printInfo(thisJoinPoint, thisEnclosingJoinPointStaticPart, v1, v2);
			}			
			
//			long startTime = System.nanoTime();						
			boolean result = proceed(v1, v2);			
//			long stopTime = System.nanoTime();
			
			// Serialize to file (only top level call with deepCount that
			// include subordinate equals calls) 
			try {
				TrackingProtocolBuffers.EqualsRelation record = TrackingProtocolBuffers.EqualsRelation.newBuilder()
				.setTimestamp(timestamp)
//				.setTag1(BCITracker.getTag(v1))
//				.setTag2(BCITracker.getTag(v2))
				.setResult(result)
				.setDeepCount(deepEqualsCount)
				.setDeepReferenceEqualityCount(deepReferenceEqualityCount)
//				.setDeepTime(stopTime - startTime)
				.setIsHashLookup(true)
				.setIsStructuralEquality(true)
				.build();
				
				// write & log
				if (recordHashCollisions || result) {
					record.writeDelimitedTo(equalsRelationOutputStream);
				}
				if (logRootEqualsSummary) {
					logger.finest(String.format("\n\nROOT_EQUALS_SUMMARY\n%s", record.toString()));
					logObjectDetails(v1);
					logObjectDetails(v2);
				}
				
			} catch (Exception e) {
				e.printStackTrace();
			}
			
			if (result == false) {
				hashTableCollision++;
			}
			if (v1 == v2) {
				hashTableSameReferenceCollision++;
			}
			
			return result;
		}	
		
		boolean around(Object v1, Object v2) : lowerEqualsCallInsideAdvice() && target(v1) && args(v2) {			
			boolean result = (v1 == v2);

//			logger.info(innerEqualsID + " Inner.");
			
			// Book keeping
			deepReferenceEqualityCount++;
					
			// Bottom-up printing
			if (logEqualsCallInsideAdvice) {
				logger.finest("[equalsCallInInsideAdvice]");
				printInfo(thisJoinPoint, thisEnclosingJoinPointStaticPart, v1, v2);
			}
			return result;
		}
	
		void printInfo(JoinPoint thisJP, JoinPoint.StaticPart enclosingJPSP, Object v1, Object v2) {
			// NOTE: Cached hashes are not yet calculated here, thus it would fail.
//			byte[] h1 = hashWriter.calculateHash((IValue) v1);
//			byte[] h2 = hashWriter.calculateHash((IValue) v2);	
			
			logger.finest(String.format(innerEqualsID + "IN[CLASS CMP] %s equals %s == %b", v1.getClass().getCanonicalName(), v2.getClass().getCanonicalName(), v1.getClass().getCanonicalName().equals(v2.getClass().getCanonicalName())));
//			logger.finest(String.format(innerEqualsID + "IN[HASH  CMP] %s equals %s == %b", toHexString(h1), toHexString(h2), result));
			logger.finest(String.format(innerEqualsID + "IN[VALUE CMP] %s equals %s == %s", v1, v2, "???"));
			logger.finest(String.format(innerEqualsID + "IN[HASHC CMP] %d equals %d == %b", v1.hashCode(), v2.hashCode(), v1.hashCode() == v2.hashCode()));
			logger.finest(String.format(innerEqualsID + "IN[ ID   CMP] %d equals %d == %b", System.identityHashCode(v1), System.identityHashCode(v2), System.identityHashCode(v1) == System.identityHashCode(v2)));	
			logger.finest(String.format(innerEqualsID + "IN[TAGS  CMP] %d equals %d == %b", BCITracker.getTag(v1), BCITracker.getTag(v2), BCITracker.getTag(v1) == BCITracker.getTag(v2)));
			
//			System.out.println(String.format(innerEqualsID + "IN[FROM...TO] %s -> %s", 
//					enclosingJPSP.getSignature().getDeclaringType().getSimpleName(),
//					v1.getClass().getSimpleName()));		
			System.out.println();
//			System.exit(0);
		}
		
	}
	
	
	/*
	 * equals(..) call tracking in program
	 */	
	static AtomicLong equalityIDCounter = new AtomicLong(1);
	
	public static aspect EqualsInstanceTracker percflow(topEqualsOutsideAdvice() || topIsEqualOutsideAdvice()) {
		
		long outerEqualityID = equalityIDCounter.getAndIncrement();
		
		final int initialDeepEqualityCount = 0;
		final int initialDeepReferenceEqualityCount = 0;
		
		int deepEqualityCount = initialDeepEqualityCount;
		int deepReferenceEqualityCount = initialDeepReferenceEqualityCount;
		
		pointcut equalsOutsideAdvice() : ( 
				execution(boolean org.eclipse.imp.pdb.facts.IValue+.equals(..)) 
				&& !execution(boolean org.eclipse.imp.pdb.facts.IExternalValue+.equals(..))
				&& !execution(boolean org.rascalmpl.interpreter.result.ICallableValue+.equals(..))
			);
		
		pointcut topEqualsOutsideAdvice() : if(isRedundancyProfilingEnabled) && !cflow(adviceexecution()) && equalsOutsideAdvice() && !cflowbelow(equalsOutsideAdvice());
		
		pointcut lowerEqualsCallOutsideAdvice() : cflowbelow(equalsOutsideAdvice()) && ( 
				execution(boolean org.eclipse.imp.pdb.facts.IValue+.equals(..)) 
				&& !execution(boolean org.eclipse.imp.pdb.facts.IExternalValue+.equals(..))
				&& !execution(boolean org.rascalmpl.interpreter.result.ICallableValue+.equals(..))
			);

		pointcut lowerEqualsCallBelowIsEqual() : cflowbelow(isEqualOutsideAdvice()) && ( 
				execution(boolean org.eclipse.imp.pdb.facts.IValue+.equals(..)) 
				&& !execution(boolean org.eclipse.imp.pdb.facts.IExternalValue+.equals(..))
				&& !execution(boolean org.rascalmpl.interpreter.result.ICallableValue+.equals(..))
			);
		
		pointcut isEqualOutsideAdvice() : ( 
				execution(boolean org.eclipse.imp.pdb.facts.IValue+.isEqual(..)) 
				&& !execution(boolean org.eclipse.imp.pdb.facts.IExternalValue+.isEqual(..))
				&& !execution(boolean org.rascalmpl.interpreter.result.ICallableValue+.equals(..))
			);	

		pointcut topIsEqualOutsideAdvice() : if(isRedundancyProfilingEnabled) && !cflow(adviceexecution()) && isEqualOutsideAdvice() && !cflowbelow(isEqualOutsideAdvice());

		pointcut lowerIsEqualCallOutsideAdvice() : cflowbelow(isEqualOutsideAdvice()) && ( 
 				execution(boolean org.eclipse.imp.pdb.facts.IValue+.isEqual(..)) 
 				&& !execution(boolean org.eclipse.imp.pdb.facts.IExternalValue+.isEqual(..))
				&& !execution(boolean org.rascalmpl.interpreter.result.ICallableValue+.equals(..))
			);
		
		pointcut lowerIsEqualCallBelowEquals() : cflowbelow(equalsOutsideAdvice()) && ( 
 				execution(boolean org.eclipse.imp.pdb.facts.IValue+.isEqual(..)) 
 				&& !execution(boolean org.eclipse.imp.pdb.facts.IExternalValue+.isEqual(..))
				&& !execution(boolean org.rascalmpl.interpreter.result.ICallableValue+.equals(..))
			);		
		
		boolean around(Object v1, Object v2) : topEqualsOutsideAdvice() && target(v1) && args(v2) {		
			boolean result;
			long timestamp = BCITracker.getCount();
			
			// Top-down printing
			if (logEqualsCallOutsideAdvice) {
				logger.finest("[equalsCallOutsideAdvice]");
				printInfo(thisJoinPoint, thisEnclosingJoinPointStaticPart, v1, v2);
			}	
			
			if (isSharingEnabled || v1 == v2 && equalsOnAliasMode == EqualsOnAliasMode.COUNT_AS_REFERENCE_EQUALITY) {
				result = (v1 == v2);
				// Book keeping
				deepReferenceEqualityCount++;
			} else {
				result = proceed(v1, v2);
				// Book keeping
				deepEqualityCount++;
			
				if (v1 == v2 && equalsOnAliasMode == EqualsOnAliasMode.EMIT_WARNING && (deepEqualityCount != initialDeepEqualityCount + 1 || deepReferenceEqualityCount != initialDeepReferenceEqualityCount)) {
					logger.warning(String.format("Class does not fast-fail on reference equality: %s", v1.getClass().getName()));
				}
			}			
			
			writeTrace(timestamp, v1, v2, result, true);
			
			// Bottom-up printing
//			if (!result)
//			printInfo(thisJoinPoint, thisEnclosingJoinPointStaticPart, result, v1, v2);
			return result;
		}	
		
		boolean around(Object v1, Object v2) : lowerEqualsCallOutsideAdvice() && target(v1) && args(v2) {			
			assert(!isSharingEnabled);

			// Top-down printing
			if (logEqualsCallInOutsideAdvice) {
				logger.finest("[equalsCallInOutsideAdvice]");
				printInfo(thisJoinPoint, thisEnclosingJoinPointStaticPart, v1, v2);
			}				

			boolean result;
			
			if (v1 == v2 && equalsOnAliasMode == EqualsOnAliasMode.COUNT_AS_REFERENCE_EQUALITY) {
				result = (v1 == v2);
				// Book keeping
				deepReferenceEqualityCount++;
			} else {
				final long oldDeepEqualityCount = deepEqualityCount;
				final long oldDeepReferenceEqualityCount = deepReferenceEqualityCount;
				
				result = proceed(v1, v2);
				// Book keeping
				deepEqualityCount++;
			
				if (v1 == v2 && equalsOnAliasMode == EqualsOnAliasMode.EMIT_WARNING && (deepEqualityCount != oldDeepEqualityCount + 1 || deepReferenceEqualityCount != oldDeepReferenceEqualityCount)) {
					logger.warning(String.format("Class does not fast-fail on reference equality: %s", v1.getClass().getName()));
				}
			}
			
			// Bottom-up printing
//			if (!result)
//			printInfo(thisJoinPoint, thisEnclosingJoinPointStaticPart, result, v1, v2);
			return result;
		}
		
		boolean around(Object v1, Object v2) : topIsEqualOutsideAdvice() && target(v1) && args(v2) {		
			boolean result;
			long timestamp = BCITracker.getCount();
			
			// Top-down printing
			if (logIsEqualCallOutsideAdvice) {
				logger.finest("[isEqualCallOutsideAdvice]");
				printInfo(thisJoinPoint, thisEnclosingJoinPointStaticPart, v1, v2);
			}	

			// dedice if a isEqual(..) could be substituted by a equals(..)
			byte[] h1 = hashWriter.calculateHash((IValue) v1);
			byte[] h2 = hashWriter.calculateHash((IValue) v2);	
			boolean isStructural = Arrays.equals(h1, h2);			
			
			if (v1 == v2 && equalsOnAliasMode == EqualsOnAliasMode.COUNT_AS_REFERENCE_EQUALITY) {
				result = (v1 == v2);
				// Book keeping
				deepReferenceEqualityCount++;
			} else if (isStructural) {
				result = true;
				// Book keeping
				deepReferenceEqualityCount++;				
			} else {
				result = proceed(v1, v2);
				// Book keeping
				deepEqualityCount++;
			
				if (v1 == v2 && equalsOnAliasMode == EqualsOnAliasMode.EMIT_WARNING && (deepEqualityCount != initialDeepEqualityCount + 1 || deepReferenceEqualityCount != initialDeepReferenceEqualityCount)) {
					logger.warning(String.format("Class does not fast-fail on reference equality: %s", v1.getClass().getName()));
				}
			}			
				
			writeTrace(timestamp, v1, v2, result, false); // TODO: think about using <isStructural> and merging equals(..) and isEqual(..)
			
			// Bottom-up printing
//			if (!result)
//			printInfo(thisJoinPoint, thisEnclosingJoinPointStaticPart, result, v1, v2);
			return result;
		}	
		
		boolean around(Object v1, Object v2) : lowerIsEqualCallOutsideAdvice() && target(v1) && args(v2) {			
			// Top-down printing
			if (logIsEqualCallInOutsideAdvice) {
				logger.finest("[isEqualCallInOutsideAdvice]");
				printInfo(thisJoinPoint, thisEnclosingJoinPointStaticPart, v1, v2);
			}	

			boolean result;
			
			// dedice if a isEqual(..) could be substituted by a equals(..)
			byte[] h1 = hashWriter.calculateHash((IValue) v1);
			byte[] h2 = hashWriter.calculateHash((IValue) v2);	
			boolean isStructural = Arrays.equals(h1, h2);	
			
			if (v1 == v2 && equalsOnAliasMode == EqualsOnAliasMode.COUNT_AS_REFERENCE_EQUALITY) {
				result = (v1 == v2);
				// Book keeping
				deepReferenceEqualityCount++;
			} else if (isStructural) {
				result = true;
				// Book keeping
				deepReferenceEqualityCount++;			
			} else {
				final long oldDeepEqualityCount = deepEqualityCount;
				final long oldDeepReferenceEqualityCount = deepReferenceEqualityCount;
				
				result = proceed(v1, v2);
				// Book keeping
				deepEqualityCount++;
			
				if (v1 == v2 && equalsOnAliasMode == EqualsOnAliasMode.EMIT_WARNING && (deepEqualityCount != oldDeepEqualityCount + 1 || deepReferenceEqualityCount != oldDeepReferenceEqualityCount)) {
					logger.warning(String.format("Class does not fast-fail on reference equality: %s", v1.getClass().getName()));
				}
			}			
			
			// Bottom-up printing
//			if (!result)
//			printInfo(thisJoinPoint, thisEnclosingJoinPointStaticPart, result, v1, v2);
			return result;
		}		
			
		before() : lowerEqualsCallBelowIsEqual() || lowerIsEqualCallBelowEquals() {
			assert(false);
		}
		
		void writeTrace(long timestamp, Object v1, Object v2, boolean result, boolean isStructuralEquality) {
			// Serialize to file (only top level call with deepCount that
			// include subordinate equals calls) 
			try {
				TrackingProtocolBuffers.EqualsRelation record = TrackingProtocolBuffers.EqualsRelation.newBuilder()
				.setTimestamp(timestamp)
//				.setTag1(BCITracker.getTag(v1))
//				.setTag2(BCITracker.getTag(v2))
				.setResult(result)
				.setIsStructuralEquality(isStructuralEquality)
				.setDeepCount(deepEqualityCount)
				.setDeepReferenceEqualityCount(deepReferenceEqualityCount)
				.build();
				
				// write & log
				record.writeDelimitedTo(equalsRelationOutputStream);
				if (logRootEqualsSummary) {
					logger.finest(String.format("\n\nROOT_EQUALS_SUMMARY\n%s", record.toString()));
					logObjectDetails(v1);
					logObjectDetails(v2);
				}
				
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
		
		void printInfo(JoinPoint thisJP, JoinPoint.StaticPart enclosingJPSP, Object v1, Object v2) {
			byte[] h1 = hashWriter.calculateHash((IValue) v1);
			byte[] h2 = hashWriter.calculateHash((IValue) v2);	
			
			System.out.println(String.format(outerEqualityID + "[CLASS CMP] %s equals %s == %b", v1.getClass().getCanonicalName(), v2.getClass().getCanonicalName(), v1.getClass().getCanonicalName().equals(v2.getClass().getCanonicalName())));
			System.out.println(String.format(outerEqualityID + "[HASH  CMP] %s equals %s == %b", toHexString(h1), toHexString(h2), toHexString(h1).equals(toHexString(h2))));
			System.out.println(String.format(outerEqualityID + "[VALUE CMP] %s equals %s == %s", v1, v2, "???"));
			System.out.println(String.format(outerEqualityID + "[HASHC CMP] %d equals %d == %b", v1.hashCode(), v2.hashCode(), v1.hashCode() == v2.hashCode()));
			System.out.println(String.format(outerEqualityID + "[ ID   CMP] %d equals %d == %b", System.identityHashCode(v1), System.identityHashCode(v2), System.identityHashCode(v1) == System.identityHashCode(v2)));	
//			
//			System.out.println(String.format(outerEqualityID + "[FROM...TO] %s -> %s", 
//					enclosingJPSP.getSignature().getDeclaringType().getSimpleName(),
//					v1.getClass().getSimpleName()));		
			System.out.println();
		}
		
	}

}
