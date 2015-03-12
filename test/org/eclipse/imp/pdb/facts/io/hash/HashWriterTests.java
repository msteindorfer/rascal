package org.eclipse.imp.pdb.facts.io.hash;

import static org.junit.Assert.*;

import java.util.Arrays;

import org.eclipse.imp.pdb.facts.IInteger;
import org.eclipse.imp.pdb.facts.ISet;
import org.eclipse.imp.pdb.facts.IValueFactory;
import org.junit.Before;
import org.junit.Test;
import org.rascalmpl.values.ValueFactoryFactory;

public class HashWriterTests {

	HashWriter hashWriter;
	HashWriter unorderedHashWriter;

	@Before
	public void setUp() {
		hashWriter = new HashWriter(false, false);
		unorderedHashWriter = new HashWriter(true, false);		
	}
	
	@Test
	public void testUnorderedVsOrderedHashesUnderCollisions() {
		IValueFactory vf = ValueFactoryFactory.getValueFactory();
		
		IInteger int1 = vf.integer(1); hashWriter.calculateHash(int1);
		IInteger int2 = vf.integer(2); hashWriter.calculateHash(int2);
		IInteger int3 = vf.integer(2); hashWriter.calculateHash(int3);
		
		ISet set12 = vf.set(int1, int2);
		ISet set21 = vf.set(int2, int1);
		
		assertTrue(Arrays.equals(hashWriter.calculateHash(set12), hashWriter.calculateHash(set21)));
		assertFalse(Arrays.equals(unorderedHashWriter.calculateHash(set12), unorderedHashWriter.calculateHash(set21)));
		
		ISet sets1221InSet = vf.set(set12, set21);
		ISet sets2112InSet = vf.set(set21, set12);

		assertTrue(Arrays.equals(hashWriter.calculateHash(sets1221InSet), hashWriter.calculateHash(sets2112InSet)));
		assertFalse(Arrays.equals(unorderedHashWriter.calculateHash(sets1221InSet), unorderedHashWriter.calculateHash(sets2112InSet)));		
	}
	
}
