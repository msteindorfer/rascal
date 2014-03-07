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

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.io.IOException;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.LinkedList;
import java.util.Queue;

import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.IValueFactory;
import org.eclipse.imp.pdb.facts.type.TypeStore;
import org.junit.Test;

public class MaximalSharingBenchmark {

	protected static final TypeStore typeStore = new TypeStore();
	protected final IValueFactory valueFactory = org.eclipse.imp.pdb.facts.impl.fast.ValueFactory.getInstance();
	
	private final int globalDepth = 20; // VALUES 2 and 1 are good for calibrating

	@Test
	public void testSingleTreeWithShareableElements_00() {
		testSingleTreeWithShareableElements(00);	
	}
	
	@Test
	public void testSingleTreeWithShareableElements_01() {
		testSingleTreeWithShareableElements(01);	
	}

	@Test
	public void testSingleTreeWithShareableElements_02() {
		testSingleTreeWithShareableElements(02);	
	}

	@Test
	public void testSingleTreeWithShareableElements_05() {
		testSingleTreeWithShareableElements(05);	
	}

	@Test
	public void testSingleTreeWithShareableElements_10() {
		testSingleTreeWithShareableElements(10);	
	}
	
	@Test
	public void testSingleTreeWithShareableElements_15() {
		testSingleTreeWithShareableElements(15);	
	}	

	@Test
	public void testSingleTreeWithShareableElements_20() {
		testSingleTreeWithShareableElements(20);	
	}
	
	public void testSingleTreeWithShareableElements(int depth) {
		long startTime = System.nanoTime();
		
		final IValue one = createTreeWithShareableElements(false, depth);
		assertTrue(one != null);
		
		long endTime = System.nanoTime();
		String outputString = String.format("%d", endTime - startTime);

		try {
			java.nio.file.Files.write(Paths.get("target/_timeBenchmark.txt"),
							outputString.getBytes("UTF-8"), StandardOpenOption.CREATE,
							StandardOpenOption.TRUNCATE_EXISTING);
		} catch (IOException e1) {
			throw new RuntimeException(e1);
		}		
	}
	
	/**
	 * Baseline benchmark that creates a tree with a given {@link #globalDepth}. All
	 * leaf nodes are the same and therefore do not have hash collisions.
	 */
	@Test
	public void testTreeWithShareableElements() {
		final IValue one = createTreeWithShareableElements(false, globalDepth);
		final IValue two = createTreeWithShareableElements(false, globalDepth);
		final IValue thr = createTreeWithShareableElements(false, globalDepth);		
		
		assertTrue(one.equals(two));
		assertTrue(one.equals(thr));
		assertTrue(two.equals(one));
		assertTrue(two.equals(thr));		
		assertTrue(thr.equals(one));
		assertTrue(thr.equals(two));		
	}
	
	@Test
	public void testTreeWithShareableElementsAndMixedEqualitiesAnnotations() {
		// TEST
		final IValue one = createTreeWithShareableElements(false, globalDepth);
		assertTrue(one.equals(one));
		assertTrue(one.isEqual(one));

		final IValue two = createTreeWithShareableElements(true, globalDepth);
		assertFalse(one.equals(two));
		assertTrue(one.isEqual(two));

		final IValue thr = createTreeWithShareableElements(false, globalDepth);
		assertTrue(thr.equals(thr));
		assertTrue(thr.isEqual(thr));
	}
		
	/**
	 * Baseline benchmark that creates a tree with a given {@link #globalDepth}. All
	 * leaf nodes are the same and therefore do not have hash collisions.
	 */
	public IValue createTreeWithShareableElements(boolean withAnnotations, int depth) {
		final Queue<IValue> queue = new LinkedList<>();
				
		final long count = (long) Math.pow(2, depth);
		assertTrue(count > 0);
		
		// create (IInteger)
		for (long i = 0; i < count; i++) {
			queue.offer(valueFactory.integer(1));
		}
		
		// reduce (INode)
		boolean exhausted = false;
		IValue result = null;
		do {
			IValue one = queue.poll();
			IValue two = queue.poll();
			
			if (two == null) {
				exhausted = true;
				result = one;
			} else {
				if (withAnnotations) {
					queue.offer(valueFactory.node("treeNode", one, two).asAnnotatable().setAnnotation("one", one));
				} else {
					queue.offer(valueFactory.node("treeNode", one, two));					
				}
			}			
		} while (!exhausted);
		
		return result;
	}
	
	@Test
	public void testSingleTreeWithUniqueElements_00() {
		testSingleTreeWithUniqueElements(00);	
	}
	
	@Test
	public void testSingleTreeWithUniqueElements_01() {
		testSingleTreeWithUniqueElements(01);	
	}

	@Test
	public void testSingleTreeWithUniqueElements_02() {
		testSingleTreeWithUniqueElements(02);	
	}

	@Test
	public void testSingleTreeWithUniqueElements_05() {
		testSingleTreeWithUniqueElements(05);	
	}

	@Test
	public void testSingleTreeWithUniqueElements_10() {
		testSingleTreeWithUniqueElements(10);	
	}
	
	@Test
	public void testSingleTreeWithUniqueElements_15() {
		testSingleTreeWithUniqueElements(15);	
	}	

	@Test
	public void testSingleTreeWithUniqueElements_20() {
		testSingleTreeWithUniqueElements(20);	
	}	
		
	public void testSingleTreeWithUniqueElements(int depth) {
		long startTime = System.nanoTime();
		
		final IValue one = createTreeWithUniqueElements(false, depth);
		assertTrue(one != null);

		long endTime = System.nanoTime();
		String outputString = String.format("%d", endTime - startTime);

		try {
			java.nio.file.Files.write(Paths.get("target/_timeBenchmark.txt"),
							outputString.getBytes("UTF-8"), StandardOpenOption.CREATE,
							StandardOpenOption.TRUNCATE_EXISTING);
		} catch (IOException e1) {
			throw new RuntimeException(e1);
		}
	}
	
	/**
	 * Baseline benchmark that creates a tree with a given {@link #globalDepth}. All
	 * leaf nodes are the same and therefore do not have hash collisions.
	 */
	@Test
	public void testTreeWithUniqueElements() {
		final IValue one = createTreeWithUniqueElements(false, globalDepth);
		final IValue two = createTreeWithUniqueElements(false, globalDepth);
		final IValue thr = createTreeWithUniqueElements(false, globalDepth);
				
		assertTrue(one.equals(two));		
		assertTrue(one.equals(thr));
		assertTrue(two.equals(one));
		assertTrue(two.equals(thr));		
		assertTrue(thr.equals(one));
		assertTrue(thr.equals(two));		
	}
	
	@Test
	public void testTreeWithUniqueElementsAndMixedEqualitiesAnnotations() {
		// TEST
		final IValue one = createTreeWithUniqueElements(false, globalDepth);
		assertTrue(one.equals(one));
		assertTrue(one.isEqual(one));

		final IValue two = createTreeWithUniqueElements(true, globalDepth);
		assertFalse(one.equals(two));
		assertTrue(one.isEqual(two));

		final IValue thr = createTreeWithUniqueElements(false, globalDepth);
		assertTrue(thr.equals(thr));
		assertTrue(thr.isEqual(thr));
	}	
	
	/**
	 * Baseline benchmark that creates a tree with a given {@link #globalDepth}. All
	 * leaf nodes are distinct integers and therefore do not have hash collisions.
	 */
	public IValue createTreeWithUniqueElements(boolean withAnnotations, int depth) { 
		Queue<IValue> queue = new LinkedList<>();
		
		final long count = (long) Math.pow(2, depth);
		assertTrue(count > 0);
		
		// create (IInteger)
		for (long i = 0; i < count; i++) {
			queue.offer(valueFactory.integer(i+1));
		}
		
		// reduce (INode)
		boolean exhausted = false;
		IValue result = null;
		do {
			IValue one = queue.poll();
			IValue two = queue.poll();
			
			if (two == null) {
				exhausted = true;
				result = one;
			} else {
				if (withAnnotations) {
					queue.offer(valueFactory.node("treeNode", one, two).asAnnotatable().setAnnotation("one", one));
				} else {
					queue.offer(valueFactory.node("treeNode", one, two));					
				}
			}			
		} while (!exhausted);
		
		return result;
	}
	
}
