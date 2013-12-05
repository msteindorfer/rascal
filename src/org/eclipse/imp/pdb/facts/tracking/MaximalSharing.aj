//package org.eclipse.imp.pdb.facts.tracking;
//
//import java.lang.ref.WeakReference;
//import java.util.WeakHashMap;
//import java.util.logging.Logger;
//
//public aspect MaximalSharing {
//
//	static Logger logger = Logger.getLogger(MaximalSharing.class.getName());
//
//	static {
//		logger.setUseParentHandlers(false);
//	}
//	
//	final static WeakHashMap<Object, WeakReference<Object>> objectPool = new WeakHashMap<>();
//	
//	pointcut equalsOutsideAdvice() : !cflow(adviceexecution()) && 
//			call(boolean org.eclipse.imp.pdb.facts.IValue+.equals(..));
//
////	pointcut equalsInsideAdvice() : cflow(adviceexecution()) && 
////			execution(boolean org.eclipse.imp.pdb.facts.IValue+.equals(..));
////	
////	pointcut equalsInsideAdviceOneLevelDeep(Object v1, Object v2) : cflowbelow(equalsInsideAdvice()) && target(v1) && args(v2) && 
////			execution(boolean org.eclipse.imp.pdb.facts.IValue+.equals(..));
//	
//	pointcut equalsInsideAdvice() : cflow(allocationWithConstructor()) && ( 
//			execution(boolean org.eclipse.imp.pdb.facts.IValue+.equals(..)) 
////			|| execution(boolean org.eclipse.imp.pdb.facts.IValue+.isEqual(..))
//		);
//
//	pointcut equalsCallInInsideAdvice() : cflow(equalsInsideAdvice()) && ( 
//			call(boolean org.eclipse.imp.pdb.facts.IValue+.equals(..)) 
////			|| call(boolean org.eclipse.imp.pdb.facts.IValue+.isEqual(..))
//		);
//	
//	
//	boolean around(Object v1, Object v2) : (equalsOutsideAdvice() || equalsCallInInsideAdvice()) && target(v1) && args(v2) {
//		return v1 == v2;
//	}
//	
//	/**
//	 * The difference between execution and call is outlined at:
//	 * http://eclipse.org/aspectj/doc/released/faq.php#q:comparecallandexecution
//	 * 
//	 * Call pointcuts are herein the preferred way, because we control the whole source at compile time,
//	 * whereas otherwise we would have to fall back to execution pointcuts.
//	 * 
//	 * With the call pointcut, we don not have to rely upon factory for each IValue implementation.
//	 */
//	pointcut allocationWithFactory() : execution(static * *.new*(..));
//	pointcut allocationWithConstructor() : call(org.eclipse.imp.pdb.facts.IValue+.new(..));
//
//	Object around() : allocationWithConstructor() {
//		final Object newObject = proceed();
//
//		WeakReference<Object> poolObjectReferene = objectPool.get(newObject);
//
//		if (poolObjectReferene == null) {
//			logger.info("CACHE MISS");
//			objectPool.put(newObject, new WeakReference<>(newObject));
//			return newObject;
//		} else {
//			Object weaklyReferencedObject = poolObjectReferene.get();
//			
//			if (weaklyReferencedObject != null) {
//				logger.info("CACHE HIT");
//				return weaklyReferencedObject;
//			} else {
//				logger.info("CACHE RACE");
//				return newObject;
//			}
//		}
//	}	
//
//}
