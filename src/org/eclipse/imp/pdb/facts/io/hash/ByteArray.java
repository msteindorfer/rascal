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
package org.eclipse.imp.pdb.facts.io.hash;

import java.util.Arrays;

import com.google.common.primitives.UnsignedBytes;

public class ByteArray implements Comparable<ByteArray> {
	public static ByteArray EMPTY = new ByteArray(new byte[] {});
	
	byte[] bytes;
	
	public ByteArray(byte[] bytes) {
		this.bytes = bytes;
	}

	public byte[] getBytes() {
		return bytes;
	}

	@Override
	public int hashCode() {
		return Arrays.hashCode(bytes);
	}

	@Override
	public boolean equals(Object other) {		
		if (other instanceof ByteArray)
			return Arrays.equals(bytes, ((ByteArray) other).bytes);
		else
			return false;
	}

	/*
	 * TODO: According to http://stackoverflow.com/questions/5108091/java-comparator-for-byte-array-lexicographic
	 * there below used comparator is faster, but I still have to measure it.
	 */
	@Override
	public int compareTo(ByteArray other) {
		return UnsignedBytes.lexicographicalComparator().compare(bytes, ((ByteArray) other).bytes);
	}
}
