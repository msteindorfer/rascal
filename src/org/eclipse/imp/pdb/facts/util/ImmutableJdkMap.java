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
package org.eclipse.imp.pdb.facts.util;

import java.util.Map;

public interface ImmutableJdkMap<K, V> extends Map<K, V> {
	ImmutableJdkMap<K, V> __put(K key, V value);

	ImmutableJdkMap<K, V> __putAll(Map<? extends K, ? extends V> map);
	
	ImmutableJdkMap<K, V> __remove(K key);
}
