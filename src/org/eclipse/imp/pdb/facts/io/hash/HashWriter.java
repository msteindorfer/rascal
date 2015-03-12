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

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.security.DigestOutputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.SortedMap;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.logging.Logger;

import org.eclipse.imp.pdb.facts.IBool;
import org.eclipse.imp.pdb.facts.IConstructor;
import org.eclipse.imp.pdb.facts.IDateTime;
import org.eclipse.imp.pdb.facts.IExternalValue;
import org.eclipse.imp.pdb.facts.IInteger;
import org.eclipse.imp.pdb.facts.IList;
import org.eclipse.imp.pdb.facts.IMap;
import org.eclipse.imp.pdb.facts.INode;
import org.eclipse.imp.pdb.facts.IRational;
import org.eclipse.imp.pdb.facts.IReal;
import org.eclipse.imp.pdb.facts.ISet;
import org.eclipse.imp.pdb.facts.ISourceLocation;
import org.eclipse.imp.pdb.facts.IString;
import org.eclipse.imp.pdb.facts.ITuple;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.impl.AnnotatedConstructorFacade;
import org.eclipse.imp.pdb.facts.impl.AnnotatedNodeFacade;
import org.eclipse.imp.pdb.facts.io.BinaryValueWriter;
import org.eclipse.imp.pdb.facts.tracking.PDBProtocolBuffers.BValue;
import org.eclipse.imp.pdb.facts.tracking.PDBProtocolBuffers.BValue.BAnnotation;
import org.eclipse.imp.pdb.facts.tracking.PDBProtocolBuffers.BValue.BType;
import org.eclipse.imp.pdb.facts.tracking.WeakIdentityHashMap;
import org.eclipse.imp.pdb.facts.visitors.IValueVisitor;

import com.google.common.hash.HashFunction;
import com.google.common.hash.Hashing;
import com.google.protobuf.ByteString;

public class HashWriter {

	static Logger logger = Logger.getLogger(HashWriter.class.getName());

	final static boolean doLogReferenceEqualityEstimateMatches = false;
	
	final static protected WeakIdentityHashMap<IValue, ByteArray> valueToHash = new WeakIdentityHashMap<>();
	
	final static protected EqualsEstimateWriter equalsEstimateWriter = new EqualsEstimateWriter();
	final static protected ProtocolObjectWriter protoObjectWriter = new ProtocolObjectWriter();
	
//	final protected boolean isOrderUnorderedDisabled = System.getProperties().containsKey("orderUnorderedDisabled");
//	final protected boolean isXORHashingEnabled = System.getProperties().containsKey("XORHashingEnabled");
//	
//	final protected HashStringWriter hashStringWriter = new HashStringWriter();
	
	final protected boolean isOrderUnorderedDisabled;
	final protected boolean isXORHashingEnabled;	
	final protected HashStringWriter hashStringWriter;
	
	public HashWriter(boolean isOrderUnorderedDisabled, boolean isXORHashingEnabled) {
		this.isOrderUnorderedDisabled = isOrderUnorderedDisabled;
		this.isXORHashingEnabled = isXORHashingEnabled;
		
		this.hashStringWriter = new HashStringWriter(isOrderUnorderedDisabled, isXORHashingEnabled);
	}
	
	
	public static byte[] toHashByteArray(IValue value) {
		return toHashViaGuavaHasher(value);
	}
	
	protected static byte[] toHashViaGuavaHasher(IValue value) {
		final HashFunction hashFunc1 = Hashing.sha256();
//		final HashFunction hashFunc2 = Hashing.murmur3_32();
		
		try {
			ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
			new BinaryValueWriter().write(value, byteArrayOutputStream);
			
			byte[] byteArray = byteArrayOutputStream.toByteArray();
			byte[] hash1 = hashFunc1.hashBytes(byteArray).asBytes();
//			byte[] hash2 = hashFunc2.hashBytes(byteArray).asBytes();
//			
//			int hashByteSize = (hashFunc1.bits() + hashFunc2.bits()) / 8;
//			byte[] result = new byte[hashByteSize];
//			System.arraycopy(hash1, 0, result, 0, hash1.length);
//			System.arraycopy(hash2, 0, result, hash1.length, hash2.length);
//
//			return result;
			
			return hash1;
		} catch (IOException iosex) {
			// this never happens
		}
		return new byte[] {};
	}	
	
	protected static byte[] toHashViaDigest(IValue value) {
		final String[] algorithms = { "SHA-256" };
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

	protected static byte[] toHashViaJavaSerialization(IValue value) {
		final HashFunction hashFunc1 = Hashing.sha256();
//		final HashFunction hashFunc2 = Hashing.murmur3_32();
		
		try {
			ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
			ObjectOutputStream objectOutputStream  = new ObjectOutputStream(byteArrayOutputStream);
			objectOutputStream.writeObject(value);
			objectOutputStream.close();
			
			byte[] byteArray = byteArrayOutputStream.toByteArray();
			byte[] hash1 = hashFunc1.hashBytes(byteArray).asBytes();
//			byte[] hash2 = hashFunc2.hashBytes(byteArray).asBytes();
//			
//			int hashByteSize = (hashFunc1.bits() + hashFunc2.bits()) / 8;
//			byte[] result = new byte[hashByteSize];
//			System.arraycopy(hash1, 0, result, 0, hash1.length);
//			System.arraycopy(hash2, 0, result, hash1.length, hash2.length);
//
//			return result;
			
			return hash1;
		} catch (IOException iosex) {
			// this never happens
		}
		return new byte[] {};
	}	
	
	protected static byte[] toHashByteArray(BValue value) {
		return toHashViaGuavaHasher(value);
	}
	
	protected static byte[] toHashViaGuavaHasher(BValue value) {
		final HashFunction hashFunc1 = Hashing.sha256();
//		final HashFunction hashFunc2 = Hashing.murmur3_32();
		
		try {
			ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
			value.writeTo(byteArrayOutputStream);
			
			byte[] byteArray = byteArrayOutputStream.toByteArray();
			byte[] hash1 = hashFunc1.hashBytes(byteArray).asBytes();
//			byte[] hash2 = hashFunc2.hashBytes(byteArray).asBytes();
//			
//			int hashByteSize = (hashFunc1.bits() + hashFunc2.bits()) / 8;
//			byte[] result = new byte[hashByteSize];
//			System.arraycopy(hash1, 0, result, 0, hash1.length);
//			System.arraycopy(hash2, 0, result, hash1.length, hash2.length);
//
//			return result;
			
			return hash1;
		} catch (IOException iosex) {
			// this never happens
		}
		return new byte[] {};
	}	
	
	protected static byte[] toHashViaDigest(BValue value) {
		final String[] algorithms = { "SHA-256" };
		final ByteArrayOutputStream digestByteArrayStream = new ByteArrayOutputStream();

		for (String algorithm : algorithms) {
			try {
				MessageDigest digest = MessageDigest.getInstance(algorithm);
				ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
				DigestOutputStream digestOutputStream = new DigestOutputStream(byteArrayOutputStream, digest);
				value.writeTo(digestOutputStream);
				digestByteArrayStream.write(digest.digest());
			} catch (IOException iosex) {
				// this never happens
			} catch (NoSuchAlgorithmException e) {
				// this never happens
			}
		}

		return digestByteArrayStream.toByteArray();
	}

	public int estimateReferenceEqualities(IValue value) {		
		try {
			return value.accept(equalsEstimateWriter);			
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}
	
	public byte[] calculateHash(IValue value) {
		try {
			if (valueToHash.containsKey(value)) {
				return valueToHash.get(value).getBytes();		
			} else {
				ByteArray protoHash = value.accept(hashStringWriter);
				
				assert (value != null);
				assert (protoHash != null);
				valueToHash.put(value, protoHash);
				
				return protoHash.getBytes();
			}
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

	private static class HashStringWriter implements IValueVisitor<ByteArray, IOException> {
		
		final protected boolean isOrderUnorderedDisabled;
		final protected boolean isXORHashingEnabled;	
		
		public HashStringWriter(boolean isOrderUnorderedDisabled, boolean isXORHashingEnabled) {
			this.isOrderUnorderedDisabled = isOrderUnorderedDisabled;
			this.isXORHashingEnabled = isXORHashingEnabled;
		}

		public ByteArray visitBoolean(IBool o) throws IOException {
			return new ByteArray(toHashByteArray(o));
		}

		public ByteArray visitReal(IReal o) throws IOException {
			return new ByteArray(toHashByteArray(o));
		}

		public ByteArray visitInteger(IInteger o) throws IOException {
			return new ByteArray(toHashByteArray(o));
		}

		public ByteArray visitRational(IRational o) throws IOException {
			return new ByteArray(toHashByteArray(o));
		}

		public ByteArray visitList(IList o) throws IOException {
			final BValue.Builder listBuilder = BValue.newBuilder().setType(BType.LIST);

			for (IValue e : o) {
				final BValue nestedValue = e.accept(protoObjectWriter);
				listBuilder.addNested(nestedValue);
			}

			return new ByteArray(toHashByteArray(listBuilder.build()));
		}

		/**
		 * NOTE: used {@link #valueToHash} to sorted map keys.
		 */
		public ByteArray visitMap(IMap o) throws IOException {
			final BValue.Builder mapBuilder = BValue.newBuilder().setType(BType.MAP);

			if (isOrderUnorderedDisabled) {
				for (Iterator<Map.Entry<IValue, IValue>> iterator = o.entryIterator(); iterator.hasNext();) {
					Map.Entry<IValue, IValue> entry = iterator.next();
			
					final BValue nestedKey = entry.getKey().accept(protoObjectWriter);					
					mapBuilder.addNested(nestedKey);
					
					final BValue nestedVal = entry.getValue().accept(protoObjectWriter);					
					mapBuilder.addNested(nestedVal);					
				}
			} else {
				if (isXORHashingEnabled) {
					/*
					 * Apply order-independent hashing.
					 */
					final byte[] xorHashKey = new byte[32];
					final byte[] xorHashVal = new byte[32];

					for (Iterator<Map.Entry<IValue, IValue>> iterator = o.entryIterator(); iterator
									.hasNext();) {
						Map.Entry<IValue, IValue> e = iterator.next();
						final byte[] curHashKey = valueToHash.get(e.getKey()).getBytes();
						final byte[] curHashVal = valueToHash.get(e.getValue()).getBytes();

						for (int i = 0; i < 32; i++) {
							xorHashKey[i] ^= curHashKey[i];
							xorHashVal[i] ^= curHashVal[i];
						}
					}

					/*
					 * Apply order-dependent concatenation to distinguish
					 * between keys and values.
					 */
					final byte[] xorHash = Hashing.sha256().newHasher(64).putBytes(xorHashKey)
									.putBytes(xorHashVal).hash().asBytes();

					// mapBuilder.setDigest(new ByteArray(xorHash));
					mapBuilder.setNestedDigest(ByteString.copyFrom(xorHash));
				} else {
					/*
					 * Topologically hashes and concatenate them.
					 */
					final SortedMap<ByteArray, List<BValue>> sortedPairsByHash = new TreeMap<>();
					for (Iterator<Map.Entry<IValue, IValue>> iterator = o.entryIterator(); iterator
									.hasNext();) {
						Map.Entry<IValue, IValue> entry = iterator.next();

						final ByteArray keyHash = valueToHash.get(entry.getKey());

						final BValue keyValue = entry.getKey().accept(protoObjectWriter);
						final BValue valValue = entry.getValue().accept(protoObjectWriter);

						sortedPairsByHash.put(keyHash, Arrays.asList(keyValue, valValue));
					}

					for (List<BValue> pair : sortedPairsByHash.values()) {
						mapBuilder.addNested(pair.get(0));
						mapBuilder.addNested(pair.get(1));
					}
				}
			}
			
			return new ByteArray(toHashByteArray(mapBuilder.build()));
		}

		/**
		 * NOTE: used {@link #valueToHash} to sorted set elements.
		 */
		public ByteArray visitSet(ISet o) throws IOException {
			final BValue.Builder setBuilder = BValue.newBuilder().setType(BType.SET);

			if (isOrderUnorderedDisabled) {
				for (Iterator<IValue> iterator = o.iterator(); iterator.hasNext();) {		
					final BValue nestedKey = iterator.next().accept(protoObjectWriter);					
					setBuilder.addNested(nestedKey);
				}
			} else {
				if (isXORHashingEnabled) {
					/*
					 * Apply order-independent hashing.
					 */
					final byte[] xorHash = new byte[32];

					for (IValue e : o) {
						final byte[] curHash = valueToHash.get(e).getBytes();

						int i = 0;
						for (byte b : curHash)
							xorHash[i] = (byte) (b ^ xorHash[i++]);
					}

					// setBuilder.setDigest(new ByteArray(xorHash));
					setBuilder.setNestedDigest(ByteString.copyFrom(xorHash));
				} else {
					/*
					 * Topologically hashes and concatenate them.
					 */
					final SortedMap<ByteArray, BValue> sortedValues = new TreeMap<>();
					for (IValue e : o) {
						final ByteArray valueHash = valueToHash.get(e);
						final BValue valueValue = e.accept(protoObjectWriter);

						sortedValues.put(valueHash, valueValue);
					}

					for (BValue e : sortedValues.values()) {
						setBuilder.addNested(e);
					}
				}
			}

			return new ByteArray(toHashByteArray(setBuilder.build()));
		}

		public ByteArray visitNode(INode o) throws IOException {
			final BValue.Builder nodeBuilder = BValue.newBuilder().setType(BType.NODE);

			nodeBuilder.setName(o.getName());
			
			// children
			for (int i = 0; i < o.positionalArity(); i++) {
				final BValue nestedValue = o.get(i).accept(protoObjectWriter);
				nodeBuilder.addNested(nestedValue);
			}
			
			// keyword arguments
			if (o.hasKeywordArguments()) {
				if (isOrderUnorderedDisabled) {
					// unsorted processing
					for (String e : o.getKeywordArgumentNames()) {
						final int keywordIdx = o.getKeywordIndex(e);
						final BValue valueValue = o.get(keywordIdx).accept(protoObjectWriter);
						nodeBuilder.addAnnotations(BAnnotation.newBuilder().setName(e).setValue(valueValue).build());
					}					
				} else {
					// sort unordered names
					final Set<String> sortedKeywords = new TreeSet<>();
					for (String e : o.getKeywordArgumentNames()) {
						sortedKeywords.add(e);
					}
					assert (sortedKeywords.size() == o.arity() - o.positionalArity());
					for (String e : sortedKeywords) {
						final int keywordIdx = o.getKeywordIndex(e);
						final BValue valueValue = o.get(keywordIdx).accept(protoObjectWriter);
						nodeBuilder.addAnnotations(BAnnotation.newBuilder().setName(e).setValue(valueValue).build());
					}
				}
			}
			
			// annotations
			if (isOrderUnorderedDisabled) {
				// unsorted processing
				final Map<String, IValue> annotations = o.asAnnotatable().getAnnotations();
				for (String e : annotations.keySet()) {
					final BValue valueValue = annotations.get(e).accept(protoObjectWriter);
					nodeBuilder.addAnnotations(BAnnotation.newBuilder().setName(e).setValue(valueValue).build());
				}
			} else {
				// sort unordered names
				final Map<String, IValue> annotations = o.asAnnotatable().getAnnotations();
				final Set<String> sortedKeys = new TreeSet<>(annotations.keySet());
				for (String e : sortedKeys) {
					final BValue valueValue = annotations.get(e).accept(protoObjectWriter);
					nodeBuilder.addAnnotations(BAnnotation.newBuilder().setName(e).setValue(valueValue).build());
				}
			}

			return new ByteArray(toHashByteArray(nodeBuilder.build()));			
		}
		
		public ByteArray visitConstructor(IConstructor o) throws IOException {
			final BValue.Builder constructorBuilder = BValue.newBuilder().setType(BType.CONSTRUCTOR);

			constructorBuilder.setName(o.getName());
			
			// children
			for (IValue e : o) {
				final BValue nestedValue = e.accept(protoObjectWriter);
				constructorBuilder.addNested(nestedValue);
			}

			// annotations
			if (isOrderUnorderedDisabled) {
				// unsorted processing
				final Map<String, IValue> annotations = o.asAnnotatable().getAnnotations();
				for (String e : annotations.keySet()) {
					final BValue valueValue = annotations.get(e).accept(protoObjectWriter);
					constructorBuilder.addAnnotations(BAnnotation.newBuilder().setName(e).setValue(valueValue).build());
				}
			} else {
				// sort unordered names
				final Map<String, IValue> annotations = o.asAnnotatable().getAnnotations();
				final Set<String> sortedKeys = new TreeSet<>(annotations.keySet());
				for (String e : sortedKeys) {
					final BValue valueValue = annotations.get(e).accept(protoObjectWriter);
					constructorBuilder.addAnnotations(BAnnotation.newBuilder().setName(e).setValue(valueValue).build());
				}
			}

			return new ByteArray(toHashByteArray(constructorBuilder.build()));
		}

		public ByteArray visitRelation(ISet o) throws IOException {
			return visitSet(o);
		}

		public ByteArray visitSourceLocation(ISourceLocation o) throws IOException {
			return new ByteArray(toHashByteArray(o));
		}

		public ByteArray visitString(IString o) throws IOException {
			return new ByteArray(toHashByteArray(o));
		}

		public ByteArray visitTuple(ITuple o) throws IOException {
			final BValue.Builder tupleBuilder = BValue.newBuilder().setType(BType.TUPLE);

			for (IValue e : o) {
				final BValue nestedValue = e.accept(protoObjectWriter);
				tupleBuilder.addNested(nestedValue);
			}

			return new ByteArray(toHashByteArray(tupleBuilder.build()));
		}

		public ByteArray visitExternal(IExternalValue o) throws IOException {
			final String location = "HashStringWriter.visitExternal(IExternalValue o)";
			throw new RuntimeException(String.format(
					"Class: %s\nValue: %s\nLocation: %s\n", o.getClass()
							.getName(), o, location));
		}

		public ByteArray visitDateTime(IDateTime o) throws IOException {
			return new ByteArray(toHashByteArray(o));
		}

		public ByteArray visitListRelation(IList o) throws IOException {
			return visitList(o);
		}
	}
	
	private static class ProtocolObjectWriter implements IValueVisitor<BValue, IOException> {
		
		public ProtocolObjectWriter() {
		}
		
		public BValue visitBoolean(IBool o) throws IOException {	
			final ByteArray digestBA = valueToHash.get(o);

			return BValue.newBuilder().setType(BType.BOOL).setDigest(ByteString.copyFrom(digestBA.getBytes())).build();
		}

		public BValue visitReal(IReal o) throws IOException {
			final ByteArray digestBA = valueToHash.get(o); 

			return BValue.newBuilder().setType(BType.REAL).setDigest(ByteString.copyFrom(digestBA.getBytes())).build();
		}

		public BValue visitInteger(IInteger o) throws IOException {
			final ByteArray digestBA = valueToHash.get(o);

			return BValue.newBuilder().setType(BType.INTEGER).setDigest(ByteString.copyFrom(digestBA.getBytes())).build();
		}

		public BValue visitRational(IRational o) throws IOException {
			final ByteArray digestBA = valueToHash.get(o);

			return BValue.newBuilder().setType(BType.RATIONAL).setDigest(ByteString.copyFrom(digestBA.getBytes())).build();
		}

		public BValue visitList(IList o) throws IOException {
			final ByteArray digestBA = valueToHash.get(o);

			return BValue.newBuilder().setType(BType.LIST).setDigest(ByteString.copyFrom(digestBA.getBytes())).build();
		}

		public BValue visitMap(IMap o) throws IOException {
			final ByteArray digestBA = valueToHash.get(o);

			return BValue.newBuilder().setType(BType.MAP).setDigest(ByteString.copyFrom(digestBA.getBytes())).build();
		}

		public BValue visitSet(ISet o) throws IOException {
			final ByteArray digestBA = valueToHash.get(o);

			return BValue.newBuilder().setType(BType.SET).setDigest(ByteString.copyFrom(digestBA.getBytes())).build();
		}

		public BValue visitConstructor(IConstructor o) throws IOException {
			final ByteArray digestBA = valueToHash.get(o);

			return BValue.newBuilder().setType(BType.CONSTRUCTOR).setDigest(ByteString.copyFrom(digestBA.getBytes())).build();
		}

		public BValue visitRelation(ISet o) throws IOException {
			return visitSet(o);
		}

		public BValue visitSourceLocation(ISourceLocation o) throws IOException {
			final ByteArray digestBA = valueToHash.get(o);

			return BValue.newBuilder().setType(BType.SOURCE_LOCATION).setDigest(ByteString.copyFrom(digestBA.getBytes())).build();
		}

		public BValue visitString(IString o) throws IOException {
			final ByteArray digestBA = valueToHash.get(o);

			return BValue.newBuilder().setType(BType.STRING).setDigest(ByteString.copyFrom(digestBA.getBytes())).build();
		}

		public BValue visitTuple(ITuple o) throws IOException {
			final ByteArray digestBA = valueToHash.get(o);

			return BValue.newBuilder().setType(BType.TUPLE).setDigest(ByteString.copyFrom(digestBA.getBytes())).build();
		}

		public BValue visitExternal(IExternalValue o) throws IOException {
			final String location = "ProtocolObjectWriter.visitExternal(IExternalValue o)";
			throw new RuntimeException(String.format(
					"Class: %s\nValue: %s\nLocation: %s\n", o.getClass()
							.getName(), o, location));
		}

		public BValue visitDateTime(IDateTime o) throws IOException {
			final ByteArray digestBA = valueToHash.get(o);

			return BValue.newBuilder().setType(BType.DATE_TIME).setDigest(ByteString.copyFrom(digestBA.getBytes())).build();
		}

		public BValue visitListRelation(IList o) throws IOException {
			return visitList(o);
		}

		public BValue visitNode(INode o) throws IOException {
			final ByteArray digestBA = valueToHash.get(o);

			return BValue.newBuilder().setType(BType.NODE).setDigest(ByteString.copyFrom(digestBA.getBytes())).build();
		}
	}

	private static class EqualsEstimateWriter implements IValueVisitor<Integer, IOException> {

		@Override
		public Integer visitString(IString o) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitString"); }
			return 0;
		}

		@Override
		public Integer visitReal(IReal o) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitReal"); }
			return 0;
		}

		@Override
		public Integer visitRational(IRational o) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitRational"); }
			return 0;
		}

		@Override
		public Integer visitList(IList o) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitList"); }
			return o.length();
		}

		@Override
		public Integer visitRelation(ISet o) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitRelation"); }
			return o.size();
		}

		@Override
		public Integer visitListRelation(IList o) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitListRelation"); }
			return o.length();
		}

		@Override
		public Integer visitSet(ISet o) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitSet"); }
			return o.size();
		}

		@Override
		public Integer visitSourceLocation(ISourceLocation o) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitSourceLocation"); }
			return 0;
		}

		@Override
		public Integer visitTuple(ITuple o) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitTuple"); }
			return o.arity();
		}

		@Override
		public Integer visitNode(INode o) throws IOException {
			if (o instanceof AnnotatedNodeFacade) {
				if (doLogReferenceEqualityEstimateMatches) { logger.info("visitAnnotatedNode"); }
				// single reference comparison of nested node + annotations
				return 1 + o.asAnnotatable().getAnnotations().size(); 
			} else {
				if (doLogReferenceEqualityEstimateMatches) { logger.info("visitNode"); }
				return o.arity();
			}
		}

		@Override
		public Integer visitConstructor(IConstructor o) throws IOException {
			if (o instanceof AnnotatedConstructorFacade) {
				if (doLogReferenceEqualityEstimateMatches) { logger.info("visitAnnotatedConstructor"); }
				// single reference comparison of nested constructor + annotations
				return 1 + o.asAnnotatable().getAnnotations().size();
			} else {
				if (doLogReferenceEqualityEstimateMatches) { logger.info("visitConstructor"); }
				return o.arity();
			}
		}

		@Override
		public Integer visitInteger(IInteger o) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitInteger"); }
			return 0;
		}

		@Override
		public Integer visitMap(IMap o) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitMap"); }
			return o.size() * 2; // one equals per key, one per value
		}

		@Override
		public Integer visitBoolean(IBool boolValue) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitBoolean"); }
			return 0;
		}

		@Override
		public Integer visitExternal(IExternalValue externalValue) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitExternal"); }
			return 0;
		}

		@Override
		public Integer visitDateTime(IDateTime o) throws IOException {
			if (doLogReferenceEqualityEstimateMatches) { logger.info("visitDateTime"); }
			return 0;
		}
		
	}
	
}
