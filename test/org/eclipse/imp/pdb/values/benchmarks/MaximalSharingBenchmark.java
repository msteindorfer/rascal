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

import java.util.LinkedList;
import java.util.Queue;

import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.IValueFactory;
import org.eclipse.imp.pdb.facts.type.TypeStore;
import org.junit.Test;

public class MaximalSharingBenchmark {

	protected static final TypeStore typeStore = new TypeStore();
	protected final IValueFactory valueFactory = org.eclipse.imp.pdb.facts.impl.fast.ValueFactory.getInstance();
	
	private final int depth = 20; // VALUES 2 and 1 are good for calibrating
	
	@Test
	public void testSingleTreeWithShareableElements() {
		final IValue one = createTreeWithShareableElements(false);
		assertTrue(one != null);
	}
	
	/**
	 * Baseline benchmark that creates a tree with a given {@link #depth}. All
	 * leaf nodes are the same and therefore do not have hash collisions.
	 */
	@Test
	public void testTreeWithShareableElements() {
		final IValue one = createTreeWithShareableElements(false);
		final IValue two = createTreeWithShareableElements(false);
		final IValue thr = createTreeWithShareableElements(false);		
		
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
		final IValue one = createTreeWithShareableElements(false);
		assertTrue(one.equals(one));
		assertTrue(one.isEqual(one));

		final IValue two = createTreeWithShareableElements(true);
		assertFalse(one.equals(two));
		assertTrue(one.isEqual(two));

		final IValue thr = createTreeWithShareableElements(false);
		assertTrue(thr.equals(thr));
		assertTrue(thr.isEqual(thr));
	}
		
	/**
	 * Baseline benchmark that creates a tree with a given {@link #depth}. All
	 * leaf nodes are the same and therefore do not have hash collisions.
	 */
	public IValue createTreeWithShareableElements(boolean withAnnotations) {
		final Queue<IValue> queue = new LinkedList<>();
				
		final long count = (long) Math.pow(2, depth);
		assertTrue(count > 0);
		
		// create (IInteger)
		for (long i = 0; i < count; i++) {
			queue.offer(valueFactory.integer(0));
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
	public void testSingleTreeWithUniqueElements() {
		final IValue one = createTreeWithUniqueElements(false);
		assertTrue(one != null);
	}
	
	/**
	 * Baseline benchmark that creates a tree with a given {@link #depth}. All
	 * leaf nodes are the same and therefore do not have hash collisions.
	 */
	@Test
	public void testTreeWithUniqueElements() {
		final IValue one = createTreeWithUniqueElements(false);
		final IValue two = createTreeWithUniqueElements(false);
		final IValue thr = createTreeWithUniqueElements(false);
				
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
		final IValue one = createTreeWithUniqueElements(false);
		assertTrue(one.equals(one));
		assertTrue(one.isEqual(one));

		final IValue two = createTreeWithUniqueElements(true);
		assertFalse(one.equals(two));
		assertTrue(one.isEqual(two));

		final IValue thr = createTreeWithUniqueElements(false);
		assertTrue(thr.equals(thr));
		assertTrue(thr.isEqual(thr));
	}	
	
	/**
	 * Baseline benchmark that creates a tree with a given {@link #depth}. All
	 * leaf nodes are distinct integers and therefore do not have hash collisions.
	 */
	public IValue createTreeWithUniqueElements(boolean withAnnotations) { 
		Queue<IValue> queue = new LinkedList<>();
		
		final long count = (long) Math.pow(2, depth);
		assertTrue(count > 0);
		
		// create (IInteger)
		for (long i = 0; i < count; i++) {
			queue.offer(valueFactory.integer(i));
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
