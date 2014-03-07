package org.eclipse.imp.pdb.values.benchmarks;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

import org.junit.Test;

public class Collision {

	@Test
	public void test() {
		Set<Integer> set1 = new HashSet<>(Arrays.asList(1));
		Set<Integer> set2 = new HashSet<>(Arrays.asList(2));
		Set<Integer> set3 = new HashSet<>(Arrays.asList(3));
		Set<Integer> set4 = new HashSet<>(Arrays.asList(4));
		Set<Integer> set12 = new HashSet<>(Arrays.asList(1, 2));
		Set<Integer> set13 = new HashSet<>(Arrays.asList(1, 3));
		Set<Integer> set14 = new HashSet<>(Arrays.asList(1, 4));
		Set<Integer> set23 = new HashSet<>(Arrays.asList(2, 3));
		
		Set<?> set = new HashSet<>(Arrays.asList(1, 2, 3, 4, set1, set2, set3, set4, set12, set13, set14, set23));
		
		System.out.println(set);
	}

}
