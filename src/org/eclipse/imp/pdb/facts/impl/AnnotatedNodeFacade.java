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
import org.eclipse.imp.pdb.facts.IList;
import org.eclipse.imp.pdb.facts.INode;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.exceptions.FactTypeUseException;
import org.eclipse.imp.pdb.facts.io.StandardTextWriter;
import org.eclipse.imp.pdb.facts.type.Type;
import org.eclipse.imp.pdb.facts.util.ImmutableJdkMap;
import org.eclipse.imp.pdb.facts.visitors.IValueVisitor;

public class AnnotatedNodeFacade implements INode {

	protected final INode content;
	protected final ImmutableJdkMap<String, IValue> annotations;
	
	private AnnotatedNodeFacade(final INode content, final ImmutableJdkMap<String, IValue> annotations) {
		this.annotations = annotations;
		this.content = content;
	}
	
	@Override
	public INode intern() {
		return (INode) org.rascalmpl.values.ValueFactoryFactory.intern(this);
	}	
	
	public static INode newAnnotatedNodeFacade(final INode content, final ImmutableJdkMap<String, IValue> annotations) {
		return new AnnotatedNodeFacade(content, annotations).intern();
	}
	
	public Type getType() {
		return content.getType();
	}

	public <T, E extends Throwable> T accept(IValueVisitor<T, E> v) throws E {
		return v.visitNode(this);
	}

	public IValue get(int i) throws IndexOutOfBoundsException {
		return content.get(i);
	}
	
	public INode set(int i, IValue newChild) throws IndexOutOfBoundsException {
		INode newContent = content.set(i, newChild);
		return newAnnotatedNodeFacade(newContent, annotations);
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
		INode newContent = content.replace(first, second, end, repl);
		return newAnnotatedNodeFacade(newContent, annotations);
	}

	@Override
	public boolean equals(Object o) {
//		if (org.rascalmpl.values.ValueFactoryFactory.isSharingEnabled) {			
//			return o == this;
//		}
		
		if(o == this) return true;
		if(o == null) return false;
		
		if(o.getClass() == getClass()){
			AnnotatedNodeFacade other = (AnnotatedNodeFacade) o;
		
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
	public IAnnotatable<? extends INode> asAnnotatable() {
		return new AbstractDefaultAnnotatable<INode>(content, annotations) {

			@Override
			protected INode wrap(INode content,
					ImmutableJdkMap<String, IValue> annotations) {
				return newAnnotatedNodeFacade(content, annotations);
			}
		};
	}

	public INode getContent() {
		return content;
	}

	public ImmutableJdkMap<String, IValue> getAnnotations() {
		return annotations;
	}
	
}
