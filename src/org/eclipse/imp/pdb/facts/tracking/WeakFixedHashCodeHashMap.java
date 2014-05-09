/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 * 
 * Origins from http://www.java2s.com/Code/Java/Collections-Data-Structure/ImplementsacombinationofWeakHashMapandIdentityHashMap.htm
 */
package org.eclipse.imp.pdb.facts.tracking;

import java.lang.ref.ReferenceQueue;
import java.lang.ref.WeakReference;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import org.eclipse.imp.pdb.facts.IValue;

/**
 * Implements a combination of WeakHashMap and IdentityHashMap. Useful for
 * caches that need to key off of a == comparison instead of a .equals.
 * 
 * <b> This class is not a general-purpose Map implementation! While this class
 * implements the Map interface, it intentionally violates Map's general
 * contract, which mandates the use of the equals method when comparing objects.
 * This class is designed for use only in the rare cases wherein
 * reference-equality semantics are required.
 * 
 * Note that this implementation is not synchronized. </b>
 */
public class WeakFixedHashCodeHashMap<K extends IValue, V> implements Map<K, V> {
	private final ReferenceQueue<K> queue = new ReferenceQueue<K>();
	private Map<FixedHashCodeReference, V> backingStore = new HashMap<FixedHashCodeReference, V>();

	public WeakFixedHashCodeHashMap() {
	}

	public void clear() {
		backingStore.clear();
		reap();
	}

	public boolean containsKey(Object key) {
//		reap();
//		return backingStore.containsKey(new FixedHashCodeReference(key));
		throw new UnsupportedOperationException();
	}
	
	public boolean containsKeyValue(IValue key) {
		reap();
		return backingStore.containsKey(new FixedHashCodeReference(key));
	}	

	public boolean containsValue(Object value) {
		reap();
		return backingStore.containsValue(value);
	}

	public Set<Map.Entry<K, V>> entrySet() {
		reap();
		Set<Map.Entry<K, V>> ret = new HashSet<Map.Entry<K, V>>();
		for (Map.Entry<FixedHashCodeReference, V> ref : backingStore.entrySet()) {
			final K key = ref.getKey().get();
			final V value = ref.getValue();
			Map.Entry<K, V> entry = new Map.Entry<K, V>() {
				public K getKey() {
					return key;
				}

				public V getValue() {
					return value;
				}

				public V setValue(V value) {
					throw new UnsupportedOperationException();
				}
			};
			ret.add(entry);
		}
		return Collections.unmodifiableSet(ret);
	}

	public Set<K> keySet() {
		reap();
		Set<K> ret = new HashSet<K>();
		for (FixedHashCodeReference ref : backingStore.keySet()) {
			ret.add(ref.get());
		}
		return Collections.unmodifiableSet(ret);
	}

	public boolean equals(Object o) {
		return backingStore.equals(((WeakFixedHashCodeHashMap) o).backingStore);
	}

	public V get(Object key) {
//		reap();
//		return backingStore.get(new FixedHashCodeReference(key));
		throw new UnsupportedOperationException();
	}
	
	public V getValue(IValue key) {
		reap();
		return backingStore.get(new FixedHashCodeReference(key));
	}	

	public V put(K key, V value) {
		reap();
		return backingStore.put(new FixedHashCodeReference(key), value);
	}

	public int hashCode() {
		reap();
		return backingStore.hashCode();
	}

	public boolean isEmpty() {
		reap();
		return backingStore.isEmpty();
	}

	public void putAll(Map t) {
		throw new UnsupportedOperationException();
	}

	public V remove(Object key) {
//		reap();
//		return backingStore.remove(new FixedHashCodeReference(key));
		throw new UnsupportedOperationException();
	}

	public V removeValue(IValue key) {
		reap();
		return backingStore.remove(new FixedHashCodeReference(key));
	}
	
	public int size() {
		reap();
		return backingStore.size();
	}

	public Collection<V> values() {
		reap();
		return backingStore.values();
	}

	private synchronized void reap() {
		Object zombie = queue.poll();

		while (zombie != null) {
			FixedHashCodeReference victim = (FixedHashCodeReference) zombie;
			backingStore.remove(victim);
			zombie = queue.poll();
		}
	}

	class FixedHashCodeReference extends WeakReference<K> {
		int hash;

		@SuppressWarnings("unchecked")
		FixedHashCodeReference(IValue obj) {
			super((K) obj, queue);
			hash = obj.fixedHashCode();
		}

		public int hashCode() {
			return hash;
		}

		public boolean equals(Object o) {
			if (this == o) {
				return true;
			}
			FixedHashCodeReference ref = (FixedHashCodeReference) o;
			if (Objects.equals(this.get(), ref.get())) {
				return true;
			}
			return false;
		}
	}
}