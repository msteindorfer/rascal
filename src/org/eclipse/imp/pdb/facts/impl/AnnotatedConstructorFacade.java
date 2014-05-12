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
package org.eclipse.imp.pdb.facts.impl;

import java.io.IOException;
import java.io.StringWriter;
import java.util.Iterator;

import org.eclipse.imp.pdb.facts.IAnnotatable;
import org.eclipse.imp.pdb.facts.IConstructor;
import org.eclipse.imp.pdb.facts.IList;
import org.eclipse.imp.pdb.facts.INode;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.exceptions.FactTypeUseException;
import org.eclipse.imp.pdb.facts.io.StandardTextWriter;
import org.eclipse.imp.pdb.facts.type.Type;
import org.eclipse.imp.pdb.facts.type.TypeStore;
import org.eclipse.imp.pdb.facts.util.ImmutableMap;
import org.eclipse.imp.pdb.facts.visitors.IValueVisitor;

public class AnnotatedConstructorFacade implements IConstructor {

	protected final IConstructor content;
	protected final ImmutableMap<String, IValue> annotations;
	
	private AnnotatedConstructorFacade(final IConstructor content, final ImmutableMap<String, IValue> annotations) {
		this.content = content;
		this.annotations = annotations;
	}

	@Override
	public IConstructor intern() {
		return (IConstructor) org.rascalmpl.values.ValueFactoryFactory.intern(this);
	}
	
	public static IConstructor newAnnotatedConstructorFacade(final IConstructor content, final ImmutableMap<String, IValue> annotations) {
		return new AnnotatedConstructorFacade(content, annotations).intern();
	}

	public <T, E extends Throwable> T accept(IValueVisitor<T, E> v) throws E {
		return v.visitConstructor(this);
	}

	public Type getType() {
		return content.getType();
	}

	public IValue get(int i) throws IndexOutOfBoundsException {
		return content.get(i);
	}

	public Type getConstructorType() {
		return content.getConstructorType();
	}
	
	public Type getUninstantiatedConstructorType() {
		return content.getUninstantiatedConstructorType();
	}

	public IValue get(String label) {
		return content.get(label);
	}

	public IConstructor set(String label, IValue newChild)
			throws FactTypeUseException {
		IConstructor newContent = content.set(label, newChild);
		return newAnnotatedConstructorFacade(newContent, annotations);
	}

	public boolean hasKeywordArguments() {
		return content.hasKeywordArguments();
	}

	public String[] getKeywordArgumentNames() {
		return content.getKeywordArgumentNames();
	}

	public int getKeywordIndex(String name) {
		return content.getKeywordIndex(name);
	}

	public IValue getKeywordArgumentValue(String name) {
		return content.getKeywordArgumentValue(name);
	}

	public int arity() {
		return content.arity();
	}

	public boolean has(String label) {
		return content.has(label);
	}

	public String toString() {
		try(StringWriter stream = new StringWriter()) {
			new StandardTextWriter().write(this, stream);
			return stream.toString();
		} catch (IOException ioex) {
			throw new RuntimeException("Should have never happened.", ioex);
		}
	}

	public int positionalArity() {
		return content.positionalArity();
	}

	public IConstructor set(int index, IValue newChild)
			throws FactTypeUseException {
		IConstructor newContent = content.set(index, newChild);
		return newAnnotatedConstructorFacade(newContent, annotations);
	}

	public String getName() {
		return content.getName();
	}

	public Iterable<IValue> getChildren() {
		return content.getChildren();
	}

	public Iterator<IValue> iterator() {
		return content.iterator();
	}

	public INode replace(int first, int second, int end, IList repl)
			throws FactTypeUseException, IndexOutOfBoundsException {
		return content.replace(first, second, end, repl);
	}

	public Type getChildrenTypes() {
		return content.getChildrenTypes();
	}

	public boolean declaresAnnotation(TypeStore store, String label) {
		return content.declaresAnnotation(store, label);
	}

	public boolean equals(Object o) {	
//		if (org.rascalmpl.values.ValueFactoryFactory.isSharingEnabled) {			
//			return o == this;
//		}
		
		if(o == this) return true;
		if(o == null) return false;
		
		if(o.getClass() == getClass()){
			AnnotatedConstructorFacade other = (AnnotatedConstructorFacade) o;
		
			return content.equals(other.content) &&
					annotations.equals(other.annotations);
		}
		
		return false;
	}

	@Override
	public boolean isEqual(IValue other) {
		if (FORWARD_ISEQUAL_TO_EQUALS) {
			return equals(other);
		} else {			
			return content.isEqual(other);
		}
	}
	
	@Override
	public int hashCode() {
		if (FORWARD_ISEQUAL_TO_EQUALS) {
			return fixedHashCode();
		} else {
			return content.hashCode();
		}
	}
	
	@Override
	public int fixedHashCode() {
		return content.hashCode() ^ (31 * annotations.hashCode());
	}

	@Override
	public boolean isAnnotatable() {
		return true;
	}
	
	@Override
	public IAnnotatable<? extends IConstructor> asAnnotatable() {
		return new AbstractDefaultAnnotatable<IConstructor>(content, annotations) {

			@Override
			protected IConstructor wrap(IConstructor content,
					ImmutableMap<String, IValue> annotations) {
				return newAnnotatedConstructorFacade(content, annotations);
			}
		};
	}

	public IConstructor getContent() {
		return content;
	}

	public ImmutableMap<String, IValue> getAnnotations() {
		return annotations;
	}
	
}
