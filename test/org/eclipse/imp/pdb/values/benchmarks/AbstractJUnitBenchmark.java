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

import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

import org.eclipse.imp.pdb.facts.IValueFactory;
import org.eclipse.imp.pdb.facts.type.TypeStore;
import org.junit.Before;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;

@RunWith(Parameterized.class)
public abstract class AbstractJUnitBenchmark {
	
	protected static TypeStore typeStore = new TypeStore();

	protected IValueFactory valueFactory;
	
	public AbstractJUnitBenchmark(IValueFactory valueFactory) throws Exception {
		this.valueFactory = valueFactory;
	}
	
	@Parameters(name="{0}")
	public static List<Object[]> getTestParameters() throws Exception {
		return Arrays.asList(new Object[][] {
				{ org.eclipse.imp.pdb.facts.impl.fast.ValueFactory.getInstance() },
		});
	}
	
	protected static List<Object[]> productOfTestParameters(List<Object[]> leftItems, List<Object[]> rightItems) {
		List<Object[]> result = new LinkedList<>();
		
		for (Object[] left : leftItems) {
			for (Object[] right : rightItems) {
				Object[] productItem = new Object[left.length + right.length];
				System.arraycopy(left, 0, productItem, 0, left.length);
				System.arraycopy(right, 0, productItem, left.length, right.length);
				
				result.add(productItem);
			}
		}
		
		return result;
	}
	
	protected static List<String> printParameters(List<Object[]> parameters) {
		List<String> result = new LinkedList<>();
		
		for (int i = 0; i < parameters.size(); i++) {
			StringBuilder sb = new StringBuilder();
			sb.append("[" + i + "]: ");

			Object[] currentRow = parameters.get(i);
			for (int j = 0; j < currentRow.length; j++) {
				sb.append(currentRow[j]);
				if (j < currentRow.length - 1) {
					sb.append(" ");
				}
			}
		
			System.out.println(sb.toString());
		}
		
		return result;
	}
		
	@SuppressWarnings("rawtypes")
	private static volatile Class lastValueFactoryClass = Object.class; // default non-factory value	
				
	public void setUpStaticValueFactorySpecificTestData() throws Exception {};

	@Before
	public void setUp() throws Exception {
		// detect change of valueFactory
		if (!lastValueFactoryClass.equals(valueFactory.getClass())) {
			setUpStaticValueFactorySpecificTestData();
			lastValueFactoryClass = valueFactory.getClass();
		}
	}		
	
}
