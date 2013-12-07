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
package org.eclipse.imp.pdb.values.benchmarks;

import java.io.InputStream;

import org.eclipse.imp.pdb.facts.ISet;
import org.eclipse.imp.pdb.facts.IValueFactory;
import org.eclipse.imp.pdb.facts.io.binary.BinaryReader;
import org.eclipse.imp.pdb.facts.type.TypeStore;
import org.junit.Test;

public class RelationResourceBenchmark {
	
	protected static final TypeStore typeStore = new TypeStore();
	protected final IValueFactory valueFactory = org.eclipse.imp.pdb.facts.impl.fast.ValueFactory.getInstance();
	
//				{ "rsf/Eclipse202a.rsf_CALL" }, 
//				{ "rsf/jdk14v2.rsf_CALL" },
//				{ "rsf/JDK140AWT.rsf_CALL" }, 
//				{ "rsf/JHotDraw52.rsf_CALL" },
//				{ "rsf/JWAM16FullAndreas.rsf_CALL" } 
	
	protected ISet readRelationResource(String relationResource) {
		try (InputStream inputStream = RelationResourceBenchmark.class
				.getResourceAsStream(relationResource)) {

			BinaryReader binaryReader = new BinaryReader(valueFactory,
					typeStore, inputStream);
			return (ISet) binaryReader.deserialize();
		} catch (Exception e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		}
	}
	
	@Test
	public void closureJHotDraw52() {
		final String relationResource = "rsf/JHotDraw52.rsf_CALL";
		final ISet testSet = readRelationResource(relationResource);
		
		testSet.asRelation().closure();
	}
	
	@Test
	public void closureJDK140AWT() {
		final String relationResource = "rsf/JDK140AWT.rsf_CALL";
		final ISet testSet = readRelationResource(relationResource);
		
		testSet.asRelation().closure();
	}
	
	@Test
	public void closurejdk14v2() {
		final String relationResource = "rsf/jdk14v2.rsf_CALL";
		final ISet testSet = readRelationResource(relationResource);
		
		testSet.asRelation().closure();
	}

	@Test
	public void closureEclipse202a() {
		final String relationResource = "rsf/Eclipse202a.rsf_CALL";
		final ISet testSet = readRelationResource(relationResource);
		
		testSet.asRelation().closure();
	}
	
	@Test
	public void closureJWAM16FullAndreas() {
		final String relationResource = "rsf/JWAM16FullAndreas.rsf_CALL";
		final ISet testSet = readRelationResource(relationResource);
		
		testSet.asRelation().closure();
	}
	
	@Test
	public void closureStarJHotDraw52() {
		final String relationResource = "rsf/JHotDraw52.rsf_CALL";
		final ISet testSet = readRelationResource(relationResource);
		
		testSet.asRelation().closureStar();
	}
	
	@Test
	public void closureStarJDK140AWT() {
		final String relationResource = "rsf/JDK140AWT.rsf_CALL";
		final ISet testSet = readRelationResource(relationResource);
		
		testSet.asRelation().closureStar();
	}
	
	@Test
	public void closureStarjdk14v2() {
		final String relationResource = "rsf/jdk14v2.rsf_CALL";
		final ISet testSet = readRelationResource(relationResource);
		
		testSet.asRelation().closureStar();
	}

	@Test
	public void closureStarEclipse202a() {
		final String relationResource = "rsf/Eclipse202a.rsf_CALL";
		final ISet testSet = readRelationResource(relationResource);
		
		testSet.asRelation().closureStar();
	}
	
	@Test
	public void closureStarJWAM16FullAndreas() {
		final String relationResource = "rsf/JWAM16FullAndreas.rsf_CALL";
		final ISet testSet = readRelationResource(relationResource);
		
		testSet.asRelation().closureStar();
	}	
		
}