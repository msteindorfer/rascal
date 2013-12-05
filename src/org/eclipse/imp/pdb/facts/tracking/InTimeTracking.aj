package org.eclipse.imp.pdb.facts.tracking;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.lang.ref.PhantomReference;
import java.lang.ref.ReferenceQueue;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.aspectj.lang.JoinPoint;
import org.eclipse.imp.pdb.facts.ISet;
import org.eclipse.imp.pdb.facts.ISetRelation;
import org.eclipse.imp.pdb.facts.ISetWriter;
import org.eclipse.imp.pdb.facts.IValueFactory;
import org.eclipse.imp.pdb.facts.impl.AbstractValue;
import org.eclipse.imp.pdb.facts.io.BinaryValueWriter;

public aspect InTimeTracking {

	static Logger logger = Logger.getLogger(InTimeTracking.class.getName());

//	static {
//		logger.setUseParentHandlers(false);
//	}
	
	final static String HOLE = "$$";
	final static String HOLE_START = "$";

	final static Set<Node> nodes = new HashSet<>();
	final static Set<Edge> edges = new HashSet<>();

//	final static WeakIdentityHashMap<Object, String> idendityToValue = new WeakIdentityHashMap<>();
//	final static WeakIdentityHashMap<Object, ObjectLifetime> idendityToTrace = new WeakIdentityHashMap<>();
	
//	final static WeakIdentityHashMap<Object, Object> referencedByIValue = new WeakIdentityHashMap<>();

	final static Set<ObjectLifetime> universe = new HashSet<>();
	final static Set<String> valueDigestUniverse = new HashSet<>();

	
	AtomicInteger eventCounter = new AtomicInteger(1);
	volatile boolean doLog = true;
	
	static Set<MyRef> R;
	static ReferenceQueue<MyRef> Q;
	static Monitor M;

	InTimeTracking() {
		// initialize object lifetime tracking data structures
		R = Collections.synchronizedSet(new HashSet<MyRef>());
		Q = new ReferenceQueue<>();
		M = new Monitor();
		M.start();
		
		// flush collected data to disk.
		Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
			@Override
			public void run() {				
				doLog = false;
				writeGraph(nodes, edges, "target/dgraph.dot");
//				writeIdentityStatistics();
//				writeValueOverlapStatistics();
//				writeSerializedObjectLifetime();
			}
		}));
	}

	@SuppressWarnings("rawtypes")
	public class MyRef extends PhantomReference {
		public JoinPoint.StaticPart sjp;
		public ObjectLifetime objectLifetime;

		@SuppressWarnings("unchecked")
		MyRef(JoinPoint.StaticPart s, ObjectLifetime objectLifetime, Object o, ReferenceQueue q) {
			super(o, q);
			this.sjp = s;
			this.objectLifetime = objectLifetime;
		}
	}

	class Monitor extends Thread {
		public void run() {
			while (true && doLog) {
				try {
					MyRef mr = (MyRef) Q.remove();

					final long eventTimestamp = eventCounter.getAndIncrement();
					mr.objectLifetime.setDtorTime(eventTimestamp);
					
					R.remove(mr);
				} catch (InterruptedException e) {
				}
			}
		}
	}

	pointcut tracedCall(): 
		(this(ISet) || this(ISetRelation)) && !cflow(adviceexecution()) &&
		(
				execution (ISet *.*(..))
		);

//	Object around() : tracedCall() {
////		logger.entering("around", "tracedCall");
//		
//		final long eventTimestamp = eventCounter.getAndIncrement();
//		Object result = proceed();
//		
////		logger.info(String.format("[target] %s %s",
////				Node.digest(thisJoinPoint.getTarget().toString()),
////				thisJoinPoint.getTarget().toString()));
//
//		final String joinPointHole = stringWithHoles(thisJoinPoint);
//
////		for (Object arg : thisJoinPoint.getArgs()) {
////			logger.info(String.format("[arg   ] %s %s",
////					Node.digest(arg.toString()), arg.toString()));
////		}
//		
//		final Node resultNode = new Node(result, digestFromValue(result));
//		nodes.add(resultNode);
//
//		final Object[] args = new Object[thisJoinPoint.getArgs().length + 1];
//		args[0] = thisJoinPoint.getTarget();
//		System.arraycopy(thisJoinPoint.getArgs(), 0, args, 1,
//				thisJoinPoint.getArgs().length);
//
//		for (int i = 0; i < args.length; i++) {
//			if (args[i] instanceof ISet || args[i] instanceof ISetRelation) {
//				final String edgeLabel = replaceHoleByIndexedHole(
//						joinPointHole,
//						new HashSet<Integer>(Arrays.asList(new Integer[] { i, args.length })));
//
//				final Node argNode = new Node(args[i], digestFromValue(args[i]));
//				nodes.add(argNode);
//
//				final Edge newEdge = new Edge(argNode, resultNode, edgeLabel, eventTimestamp);
//				edges.add(newEdge);
//			}
//		}
//
////		logger.info(String.format("[result] %s %s", Node.digest(result.toString()), result.toString()));
//		
////		logger.exiting("around", "tracedCall");
//		return result;
//	}

	@SuppressWarnings("unchecked")
	private String digestFromValue(Object result) {
		if (result instanceof ISetRelation)
			return ((AbstractValue) ((ISetRelation<ISet>) result).asSet()).toHashString();
		else
			return ((AbstractValue) result).toHashString();
		
	}
	
//	pointcut tracedObjectsInitialize(): !within(ISetFactTracking) && (
//			execution(org.eclipse.imp.pdb.facts.impl.primitive.BoolValue.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.AnnotatedConstructorFacade.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.fast.Constructor.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.AnnotatedNodeFacade.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.fast.Node.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.primitive.DateTimeValues.*.new(..))
////				|| execution(org.eclipse.imp.pdb.facts.IExternalValue+.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.primitive.IntegerValue.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.primitive.BigIntegerValue.new(..))	
//				|| execution(org.eclipse.imp.pdb.facts.impl.fast.List.new(..))
////				|| execution(org.eclipse.imp.pdb.facts.IListAlgebra+.new(..))
////				|| execution(org.eclipse.imp.pdb.facts.IListRelation+.new(..))
////				|| execution(org.eclipse.imp.pdb.facts.IListWriter+.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.fast.Map.new(..))
////				|| execution(org.eclipse.imp.pdb.facts.IMapWriter+.new(..))
////				|| execution(org.eclipse.imp.pdb.facts.INumber+.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.primitive.RationalValue.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.primitive.BigDecimalValue.new(..))
////				|| execution(org.eclipse.imp.pdb.facts.IRelationalAlgebra+.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.fast.Set.new(..))
////				|| execution(org.eclipse.imp.pdb.facts.ISetAlgebra+.new(..))
////				|| execution(org.eclipse.imp.pdb.facts.ISetRelation+.new(..))
////				|| execution(org.eclipse.imp.pdb.facts.ISetWriter+.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.SourceLocationValues.*.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.primitive.StringValue.new(..))
//				|| execution(org.eclipse.imp.pdb.facts.impl.fast.Tuple.new(..))
////				|| execution(org.eclipse.imp.pdb.facts.IValue+.new(..))				
////				|| execution(org.eclipse.imp.pdb.facts.IValueFactory+.new(..))
////				|| execution(org.eclipse.imp.pdb.facts.IWriter+.new(..))
//			);

//	Object around() : tracedObjectsInitialize() {
//		final Object result = proceed();
//		
//		if (doLog) {
//		final long eventTimestamp = eventCounter.getAndIncrement();
//
//		final Object reference = thisJoinPoint.getTarget();
//		final String digest = ((AbstractValue) reference).toHashString();
//
//		final ObjectLifetime objectLifetime = new ObjectLifetime(reference, digest, eventTimestamp);
////		objectLifetime.measuredSizeInBytes = 0; // temporary fix to set size to zero (= switching it off)
////		objectLifetime.measuredSizeInBytes = objectexplorer.MemoryMeasurer.measureBytes(reference); 
//
//		Predicate<Object> isRoot = new Predicate<Object>() {
//			@Override
//			public boolean apply(Object arg0) {
//				return arg0 == reference;
//			}
//		};
//		
////		Predicate<Object> isUnseen = new Predicate<Object>() {
////			@Override
////			public boolean apply(Object arg0) {
////				
////				if (referencedByIValue.containsKey(arg0)) {
////					return false;
////				} else {
////					referencedByIValue.put(arg0, null);
////					return true;
////				}
////			}
////		};
//		
////		Predicate<Object> p = Predicates.or(isRoot,
////				Predicates.not(Predicates.instanceOf(IValue.class)));
//				
//		objectLifetime.measuredSizeInBytes = objectexplorer.MemoryMeasurer.measureBytes(reference, isRoot);
//		
////		logger.info(String.format("%s: %s", reference.getClass().getName(), objectexplorer.MemoryMeasurer.measureBytes(reference, p)));
////		logger.info(String.format("NG: %s", objectexplorer.ObjectGraphMeasurerNG.measure(reference)));
//		
////		idendityToValue.put(reference, digest);
////		idendityToTrace.put(reference, objectLifetime);
//
//		universe.add(objectLifetime);
////		valueDigestUniverse.add(digest);
//		
////		logger.info(String.format("[init]   %s %s", digest, reference));
//		
//		MyRef mr = new MyRef(thisJoinPointStaticPart, objectLifetime, reference, Q);
//		R.add(mr);
//		}
//		
//		return result;
//	}


	/**
	 * Inverts surjective IdendityHashMap.
	 * 
	 * @param map
	 * @return
	 */
	<K, V> Map<V, Set<K>> invertSurjectiveMap(WeakIdentityHashMap<K, V> map) {
		final Map<V, Set<K>> result = new HashMap<>();

		for (Map.Entry<K, V> entry : map.entrySet()) {
			final K key = entry.getKey();
			final V val = entry.getValue();

			if (result.containsKey(val)) {
				result.get(val).add(key);
			} else {
				Set<K> keys = Collections.newSetFromMap(new WeakIdentityHashMap<K, Boolean>());
				keys.add(key);
				result.put(val, keys);
			}
		}

		return Collections.unmodifiableMap(result);
	}

	void diff(ISet set1, ISet set2) {
		if (set1.isRelation() && set2.isRelation()) {
			logger.info(String.format("[-Edges]", set1.subtract(set2).toString()));
			logger.info(String.format("[+Edges]", set2.subtract(set1).toString()));
			logger.info(String.format("[~Edges]", set1.intersect(set2).toString()));
			logger.info(String.format("[-Nodes]", set1.asRelation().carrier()
					.subtract(set2.asRelation().carrier()).toString()));
			logger.info(String.format("[+Nodes]", set2.asRelation().carrier()
					.subtract(set1.asRelation().carrier()).toString()));
			logger.info(String.format("[~Nodes]", set1.asRelation().carrier()
					.intersect(set2.asRelation().carrier()).toString()));
			logger.info(String.format("[Sparsity1]", set1.size()
					/ Math.pow(set1.asRelation().carrier().size(), 2)));
			logger.info(String.format("[Sparsity2]", set2.size()
					/ Math.pow(set2.asRelation().carrier().size(), 2)));
		} else {
			logger.info("Not a relation.");
		}
	}

	String stringWithHoles(JoinPoint joinPoint) {
		StringBuilder result = new StringBuilder();

		result.append(HOLE);
		result.append(".");
		result.append(joinPoint.getSignature().getName());
		result.append("(");

		Object[] args = joinPoint.getArgs();
		for (int i = 0; i < args.length; i++) {
			result.append(HOLE);

			if (i + 1 != args.length) {
				result.append(", ");
			}
		}

		result.append(")");

		result.append(": ");
		result.append(HOLE);

		return result.toString();
	}

	String replaceHoleByIndexedHole(String source, Set<Integer> holeIndices) {
		StringBuffer result = new StringBuffer();

		Pattern p = Pattern.compile(Pattern.quote(HOLE));
		Matcher m = p.matcher(source);

		for (int i = 0; m.find(); i++) {
			if (holeIndices.contains(i)) {
				m.appendReplacement(result, "\\$" + i);
			} else {
				m.appendReplacement(result, "\\$\\$");
			}
		}
		m.appendTail(result);

		return result.toString();

	}

	public void writeGraph(Set<Node> nodes, Set<Edge> edges, String filename) {
		try (PrintWriter out = new PrintWriter(filename)) {
			
			out.println("digraph ValueFlow {");
			for (Node node : nodes) {
				out.println(node);
			}
			for (Edge edge : edges) {
				out.println(edge);
			}
			out.println("}");

		} catch (Throwable throwable) {
			throwable.printStackTrace();
		}
	}

	public void writeIdentityStatistics() {
		// logger.info(String.valueOf(idendityToTrace.size()));
		// logger.info(String.valueOf(idendityToValue.size()));
		// logger.info(String.valueOf(invertSurjectiveMap(idendityToValue).size()));
		// logger.info(String.valueOf(universe.size()));
		// logger.info(String.valueOf(universe));
	}

//	public void writeValueOverlapStatistics() {
////		logger.entering(ISetFactTracking.class.toString(), "writeValueOverlapStatistics");
//		
//		try (PrintWriter out = new PrintWriter("target/val-overlap-stat.log")) {
//
//			SortedSet<String> sortedValueDigestUniverse = new TreeSet<String>(valueDigestUniverse);
//			
//			for (String valueDigest : sortedValueDigestUniverse) {
//				SortedSet<ObjectLifetime> lifetimeByDigest = new TreeSet<>();
//
//				// group by
//				for (ObjectLifetime o : universe) {
//					if (o.getDigest().equals(valueDigest)) {
//						lifetimeByDigest.add(o);
//					}
//				}
//			
//				List<ObjectLifetime> run = new LinkedList<>();
//				long ctorMin = 0;
//				long dtorMax = 0;
//				// group overlapping runs
//				for (ObjectLifetime curr : lifetimeByDigest) {
//					if (run.isEmpty()) { 
//						// reset initially
//						run.add(curr);
//						ctorMin = curr.ctorTime;
//						dtorMax = (curr.dtorTime == -1) ? Long.MAX_VALUE : curr.dtorTime;
//					} else {
//						if (ctorMin < curr.ctorTime && curr.ctorTime < dtorMax) {					
//							run.add(curr);
//							dtorMax = Math.max(dtorMax, (curr.dtorTime == -1) ? Long.MAX_VALUE : curr.dtorTime);
//						} else {
////							if (run.size() > 1) {
//								for (ObjectLifetime r : run) {
//									out.println(r);
////									logger.info(r.toString());
//								}
//								out.println("---");
////								logger.info("---");
////							}
//							
//							// write to disk
//							writeGraphForRun(run);
//							
//							// reset
//							run.clear();
//							run.add(curr);
//							ctorMin = curr.ctorTime;
//							dtorMax = (curr.dtorTime == -1) ? Long.MAX_VALUE : curr.dtorTime;
//						}
//					}
//				}			
//			}
//			
//		} catch (Throwable throwable) {
//			throwable.printStackTrace();
//		}
//		
////		logger.exiting(ISetFactTracking.class.toString(), "writeValueOverlapStatistics");
//	}
//
//	void writeGraphForRun(List<ObjectLifetime> run) {
//		final Set<Node> filteredNodes = new HashSet<>();
//		final Set<Edge> filteredEdges = new HashSet<>();
//		
//		for (ObjectLifetime o : run) {
//			for (Node aNode : nodes) {
//				if (aNode.getDigest().equals(o.digest)) {
//					filteredNodes.add(aNode);
//				}
//			}
//		}
//					
//		int oldNodeCount;
//		int oldEdgeCount;
//		
//		do {
//			oldNodeCount = filteredNodes.size();
//			oldEdgeCount = filteredEdges.size();
//
//			for (ObjectLifetime o : run) {
//				for (Edge aEdge : edges) {
//					if (aEdge.getFromOLT().equals(o) || aEdge.getToOLT().equals(o)) {
//						filteredEdges.add(aEdge);
//					}
//				}
//			}
//			
////			for (Node aNode : nodes) {
////				for (Edge aEdge : edges) {
////					if (aEdge.getFrom().equals(aNode) || aEdge.getTo().equals(aNode)) {
////						filteredEdges.add(aEdge);
////					}
////				}
////			}
//		} while (oldNodeCount != filteredNodes.size() || oldEdgeCount != filteredEdges.size());
//		
//		writeGraph(filteredNodes, filteredEdges, "target/dgraph-run" + System.identityHashCode(run) + ".dot");
//	}
	
	void writeSerializedObjectLifetime() {
		try (OutputStream outputStream = new FileOutputStream("target/universe.raw")) {
			for (ObjectLifetime o : universe) {
				o.toProtoBuf().writeDelimitedTo(outputStream);
			}	
		} catch (IOException e) {
			e.printStackTrace();
		}		
	}
	
}
