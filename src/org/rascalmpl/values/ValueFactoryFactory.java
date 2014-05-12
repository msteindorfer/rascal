/*******************************************************************************
 * Copyright (c) 2009-2013 CWI
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:

 *   * Jurgen J. Vinju - Jurgen.Vinju@cwi.nl - CWI
 *   * Tijs van der Storm - Tijs.van.der.Storm@cwi.nl
 *   * Paul Klint - Paul.Klint@cwi.nl - CWI
 *   * Arnold Lankamp - Arnold.Lankamp@cwi.nl
*******************************************************************************/
package org.rascalmpl.values;

import java.lang.ref.WeakReference;
import java.util.Map;
import java.util.WeakHashMap;

import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.IValueFactory;
import org.eclipse.imp.pdb.facts.impl.fast.ValueFactory;
import org.eclipse.imp.pdb.facts.tracking.AnotherWeakHashMap;
import org.eclipse.imp.pdb.facts.tracking.WeakFixedHashCodeHashMap;

public class ValueFactoryFactory{

	public final static boolean isSharingEnabled = System.getProperties().containsKey("sharingEnabled");
	
	public static IValue intern(final IValue prototype) {
		if (isSharingEnabled) {
			final WeakReference<IValue> poolObjectReferene = getFromObjectPool(prototype);

			if (poolObjectReferene == null) {
//				System.out.println("MISS");
				putIntoObjectPool(prototype);
				return prototype;
			} else {
				final IValue weaklyReferencedObject = poolObjectReferene.get();

				if (weaklyReferencedObject != null) {
//					System.out.println("HIT");
					return weaklyReferencedObject;
				} else {
//					System.out.println("RACE");
					putIntoObjectPool(prototype); // TODO: follow-up
					return prototype;
				}
			}
		} else {
			return prototype;
		}
	}
	
	final static Map<IValue, WeakReference<IValue>> objectPool = new AnotherWeakHashMap<>();
//	final static WeakFixedHashCodeHashMap<IValue, WeakReference<IValue>> objectPool = new WeakFixedHashCodeHashMap<>();
	
	static WeakReference<IValue> getFromObjectPool(IValue prototype) {
		return objectPool.get(prototype);
	}
	
	static void putIntoObjectPool(IValue prototype) {
		objectPool.put(prototype, new WeakReference<>(prototype));
	}

		
	public static IValueFactory getValueFactory(){
		return ValueFactory.getInstance();
	}
}
