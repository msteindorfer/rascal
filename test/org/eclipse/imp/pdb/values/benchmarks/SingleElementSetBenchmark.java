/*******************************************************************************
 * Copyright (c) 2013 CWI
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *
 *   * Michael Steindorfer - Michael.Steindorfer@cwi.nl - CWI  
 *******************************************************************************/
package org.eclipse.imp.pdb.values.benchmarks;

import org.eclipse.imp.pdb.facts.ISet;
import org.eclipse.imp.pdb.facts.IValueFactory;
import org.eclipse.imp.pdb.facts.type.TypeStore;
import org.junit.Test;

public class SingleElementSetBenchmark {

	protected static final TypeStore typeStore = new TypeStore();
	protected final IValueFactory valueFactory = org.eclipse.imp.pdb.facts.impl.fast.ValueFactory.getInstance();
		
	@Test
	public void testUnionSingleElementIntegerSets_1_000() {
		unionSingleElementIntegerSets(1_000);
	}

	@Test
	public void testUnionSingleElementIntegerSets_5_000() {
		unionSingleElementIntegerSets(5_000);
	}
	
	@Test
	public void testUnionSingleElementIntegerSets_10_000() {
		unionSingleElementIntegerSets(10_000);
	}
	
	@Test
	public void testUnionSingleElementIntegerSets_15_000() {
		unionSingleElementIntegerSets(15_000);
	}

	@Test
	public void testUnionSingleElementIntegerSets_20_000() {
		unionSingleElementIntegerSets(20_000);
	}

	@Test
	public void testUnionSingleElementIntegerSets_30_000() {
		unionSingleElementIntegerSets(30_000);
	}
	
	public ISet unionSingleElementIntegerSets(final int singleValueSetsCount) {
		ISet[] singleValueSets = new ISet[singleValueSetsCount];
		for (int i = 0; i < singleValueSets.length; i++) {
			singleValueSets[i] = valueFactory.set(valueFactory.integer(i));
		}

		
		ISet resultSet = valueFactory.set();
		
		for (int i = 0; i < singleValueSets.length; i++) {
			resultSet = resultSet.union(singleValueSets[i]);
		}
		
		return resultSet;
	}
	
}
