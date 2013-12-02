/*******************************************************************************
 * Copyright (c) 2009-2013 CWI
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:

 *   * Jurgen J. Vinju - Jurgen.Vinju@cwi.nl - CWI
 *   * Mark Hills - Mark.Hills@cwi.nl (CWI)
 *   * Arnold Lankamp - Arnold.Lankamp@cwi.nl
 *   * Anastasia Izmaylova - A.Izmaylova@cwi.nl - CWI
*******************************************************************************/
package org.rascalmpl.interpreter.result;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import org.eclipse.imp.pdb.facts.IAnnotatable;
import org.eclipse.imp.pdb.facts.IExternalValue;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.exceptions.IllegalOperationException;
import org.eclipse.imp.pdb.facts.type.Type;
import org.eclipse.imp.pdb.facts.type.TypeFactory;
import org.eclipse.imp.pdb.facts.visitors.IValueVisitor;
import org.rascalmpl.interpreter.Evaluator;
import org.rascalmpl.interpreter.IEvaluator;
import org.rascalmpl.interpreter.IEvaluatorContext;
import org.rascalmpl.interpreter.IRascalMonitor;
import org.rascalmpl.interpreter.control_exceptions.Failure;
import org.rascalmpl.interpreter.control_exceptions.MatchFailed;
import org.rascalmpl.interpreter.env.Environment;
import org.rascalmpl.interpreter.staticErrors.ArgumentsMismatch;

public class ComposedFunctionResult extends Result<IValue> implements IExternalValue, ICallableValue {
	private final static TypeFactory TF = TypeFactory.getInstance();
	
	private final Result<IValue> left;
	private final Result<IValue> right;
	private final boolean isStatic;
	private Type type;
	
	
	public <T extends Result<IValue> & IExternalValue & ICallableValue, 
			U extends Result<IValue> & IExternalValue & ICallableValue> 
				ComposedFunctionResult(T left, U right, Type type, IEvaluatorContext ctx) {
					super(type, null, ctx);
					this.left = left;
					this.right = right;
					this.type = type;
					this.isStatic = left.isStatic() && right.isStatic();
				}
	
	public <T extends Result<IValue> & IExternalValue & ICallableValue, 
	U extends Result<IValue> & IExternalValue & ICallableValue> 
		ComposedFunctionResult(T left, U right, IEvaluatorContext ctx) {
			super(TF.voidType(), null, ctx);
			this.left = left;
			this.right = right;
			this.type = super.type;
			try {
				// trying to compute the composed type 
				type = left.getType().compose(right.getType());
			} catch(IllegalOperationException e) {
				// if the type of one of the arguments is of the type 'value' (e.g., the type of an overloaded function can be of the type 'value')
			}
			this.isStatic = left.isStatic() && right.isStatic();
		}

	@SuppressWarnings("unchecked")
	private ComposedFunctionResult(ICallableValue left, ICallableValue right, Type type, IEvaluatorContext ctx) {
		super(type, null, ctx);
		this.left = (Result<IValue>) left;
		this.right = (Result<IValue>) right;
		this.type = type;
		this.isStatic = left.isStatic() && right.isStatic();
	}
	
	
	@Override
	public ComposedFunctionResult cloneInto(Environment env) {
		return new ComposedFunctionResult(((ICallableValue)left).cloneInto(env), 
				((ICallableValue)right).cloneInto(env), type, ctx);
	}

	public boolean isNonDeterministic() {
		return false;
	}
		
	@Override
	public int getArity() {
		throw new UnsupportedOperationException();
	}

	@Override
	public boolean hasVarArgs() {
		throw new UnsupportedOperationException();
	}
	
	@Override
	public boolean isStatic() {
		return isStatic;
	}
	
	@Override
	public Type getType() {
		return this.type;
	}
	
	public Result<IValue> getLeft() {
		return this.left;
	}
	
	public Result<IValue> getRight() {
		return this.right;
	}
	
	@Override
	public Result<IValue> call(IRascalMonitor monitor, Type[] argTypes, IValue[] argValues,
	    Map<String, IValue> keyArgValues) {
	  IRascalMonitor old = ctx.getEvaluator().setMonitor(monitor);
	  try {
	    return call(argTypes, argValues, keyArgValues);
	  }
	  finally {
	    ctx.getEvaluator().setMonitor(old);
	  }
	}
	
	@Override
  public Result<IValue> call(Type[] argTypes, IValue[] argValues, Map<String, IValue> keyArgValues) {
    Result<IValue> rightResult = right.call(argTypes, argValues, null);
    return left.call(new Type[] { rightResult.getType() }, new IValue[] { rightResult.getValue() }, keyArgValues);
  }
	
	@Override
	public <U extends IValue, V extends IValue> Result<U> add(Result<V> right) {
		return right.addFunctionNonDeterministic(this);
	}
	
	@Override
	public ComposedFunctionResult addFunctionNonDeterministic(AbstractFunction that) {
		return new ComposedFunctionResult.NonDeterministic(that, this, ctx);
	}
	
	@Override
	public ComposedFunctionResult addFunctionNonDeterministic(OverloadedFunction that) {
		return new ComposedFunctionResult.NonDeterministic(that, this, ctx);
	}
	
	@Override
	public ComposedFunctionResult addFunctionNonDeterministic(ComposedFunctionResult that) {
		return new ComposedFunctionResult.NonDeterministic(that, this, ctx);
	}
	
	@Override
	public <U extends IValue, V extends IValue> Result<U> compose(Result<V> right) {
		return right.composeFunction(this);
	}
	
	@Override
	public ComposedFunctionResult composeFunction(AbstractFunction that) {
		return new ComposedFunctionResult(that, this, ctx);
	}
	
	@Override
	public ComposedFunctionResult composeFunction(OverloadedFunction that) {
		return new ComposedFunctionResult(that, this, ctx);
	}
	
	@Override
	public ComposedFunctionResult composeFunction(ComposedFunctionResult that) {
		return new ComposedFunctionResult(that, this, ctx);
	}

	
	public <T, E extends Throwable> T accept(IValueVisitor<T,E> v) throws E {
		return v.visitExternal(this);
	}

	public boolean isEqual(IValue other) {
		return other == this;
	}
	
	@Override
	public IValue getValue() {
		return this;
	}
	
	@Override
	public String toString() {
		return left.toString() + " 'o' " + right.toString();
	}

	@Override
	public IEvaluator<Result<IValue>> getEval() {
		return (Evaluator) ctx;
	}
	
	public static class NonDeterministic extends ComposedFunctionResult {
		private final static TypeFactory TF = TypeFactory.getInstance();
		
		public <T extends Result<IValue> & IExternalValue & ICallableValue, 
				U extends Result<IValue> & IExternalValue & ICallableValue> 
					NonDeterministic(T left, U right, IEvaluatorContext ctx) {	
						super(left, right, TF.voidType().lub(left.getType()).lub(right.getType()), ctx);
					}
		
		@Override
		public boolean isNonDeterministic() {
			return true;
		}
				
		@Override
		public Result<IValue> call(Type[] argTypes, IValue[] argValues, Map<String, IValue> keyArgValues) {
			Failure f1 = null;
			try {
				try {
					return getRight().call(argTypes, argValues, keyArgValues);
				} catch(MatchFailed e) {
					// try another one
				} catch(Failure e) {
					// try another one
				}
		 		return getLeft().call(argTypes, argValues, keyArgValues);
			} 
			catch (MatchFailed e) {
				List<AbstractFunction> candidates = Arrays.<AbstractFunction>asList((AbstractFunction) getLeft(), (AbstractFunction) getRight());
        throw new ArgumentsMismatch("+ composition", candidates, argTypes, ctx.getCurrentAST());
			} 
			catch(Failure f2) {
				throw new Failure("Both functions in the '+' composition have failed:\n " 
									+ getLeft().toString() + ",\n" + getRight().toString());
			}
		}
		
		@Override
		public String toString() {
			return getLeft().toString() + " '+' " + getRight().toString();
		}

	}

	@Override
	public boolean hasKeywordArgs() {
		return false;
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
	
	@Override
	public int fixedHashCode() {
		return hashCode();
	}
	
}
