package org.eclipse.imp.pdb.facts.tracking;

public aspect UniverseRehash {
	
	public volatile boolean isRehasing;
	
	after() : call(* AnotherWeakHashMap.resize(..)) {		
		System.out.println("YEP!");
//		isRehasing = true;
//		proceed();
//		isRehasing = false;
	}
}