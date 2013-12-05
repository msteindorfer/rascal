/*******************************************************************************
 * Copyright (c) 2009-2013 CWI
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *
 *   * Jurgen Vinju - interface and implementation
 *   * Michael Steindorfer - Michael.Steindorfer@cwi.nl - CWI
 *******************************************************************************/
package org.eclipse.imp.pdb.facts.impl;
	
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.StringWriter;
import java.security.DigestOutputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import org.eclipse.imp.pdb.facts.IAnnotatable;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.exceptions.IllegalOperationException;
import org.eclipse.imp.pdb.facts.io.BinaryValueWriter;
import org.eclipse.imp.pdb.facts.io.StandardTextWriter;

public abstract class AbstractValue implements IValue {

	@Override
	public int fixedHashCode() {
		return hashCode();
	}

	protected AbstractValue() {
		super();
	}
	
	@Override
	public String toString() {
		try(StringWriter stream = new StringWriter()) {
			new StandardTextWriter().write(this, stream);
			return stream.toString();
		} catch (IOException ioex) {
			// this never happens
		}
		return "";
	}

	public String toHashString() {
		return toHashString(this);
	}

	public byte[] toHashByteArray() {
		return toHashByteArray(this);
	}
	
	public static String toHashString(IValue value) {
		return toHexString(toHashViaBinaryWriter(value));
	}

	public static byte[] toHashByteArray(IValue value) {
		return toHashViaBinaryWriter(value);
	}
	
	protected static byte[] toHashViaBinaryWriter(IValue value) {
		final String[] algorithms = { "MD5", "SHA1" };
		final ByteArrayOutputStream digestByteArrayStream = new ByteArrayOutputStream();
		
		for (String algorithm : algorithms) {
			try {
				MessageDigest digest = MessageDigest.getInstance(algorithm);
				ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
				DigestOutputStream digestOutputStream = new DigestOutputStream(
						byteArrayOutputStream, digest);
				new BinaryValueWriter().write(value, digestOutputStream);
				digestByteArrayStream.write(digest.digest());
			} catch (IOException iosex) {
				// this never happens
			} catch (NoSuchAlgorithmException e) {
				// this never happens
			}
		}
		
		return digestByteArrayStream.toByteArray();
	}
	
	protected static byte[] toHashViaStringWriter(IValue value) {
		final String[] algorithms = { "MD5", "SHA1" };
		final ByteArrayOutputStream digestByteArrayStream = new ByteArrayOutputStream();
		
		for (String algorithm : algorithms) {
			try {
				MessageDigest digest = MessageDigest.getInstance(algorithm);
				ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
				DigestOutputStream digestOutputStream = new DigestOutputStream(
						byteArrayOutputStream, digest);
				OutputStreamWriter outputStreamWriter = new OutputStreamWriter(
						digestOutputStream);
				new StandardTextWriter().write(value, outputStreamWriter);
				digestByteArrayStream.write(digest.digest());
			} catch (IOException iosex) {
				// this never happens
			} catch (NoSuchAlgorithmException e) {
				// this never happens
			}
		}
		
		return digestByteArrayStream.toByteArray();		
	}

	protected static String toHexString(byte[] bytes) {
		char[] hexChars = toHexCharArray(bytes);
		return new String(hexChars);
	}	
	
	/**
	 * Converts a byte array into a hex string with leading zeros.
	 * 
	 * For a discussion about the implementation see: 
	 * http://stackoverflow.com/questions/332079/in-java-how-do-i-convert-a-byte-array-to-a-string-of-hex-digits-while-keeping-l
	 * 
	 * @param bytes an input byte array
	 * @return hex string with capital letters
	 */
	protected static char[] toHexCharArray(byte[] bytes) {
		char[] hexArray = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
				'A', 'B', 'C', 'D', 'E', 'F' };
		char[] hexChars = new char[bytes.length * 2];
		
		int charPairAsInt;
		for (int i = 0; i < bytes.length; i++) {
			charPairAsInt = bytes[i] & 0xFF;
			hexChars[i * 2]     = hexArray[charPairAsInt / 16]; // first  character
			hexChars[i * 2 + 1] = hexArray[charPairAsInt % 16]; // second character
		}
		return hexChars;
	}
	
	@Override
	public boolean isAnnotatable() {
		return false;
	}

	@Override
	public IAnnotatable<? extends IValue> asAnnotatable() {
		throw new IllegalOperationException(
				"Cannot be viewed as annotatable.", getType());
	}
	
}
