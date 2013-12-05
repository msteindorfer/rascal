/*
 * %W% %E%
 * 
 * Copyright (c) 2006, Oracle and/or its affiliates. All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * -Redistribution of source code must retain the above copyright notice, this
 *  list of conditions and the following disclaimer.
 * 
 * -Redistribution in binary form must reproduce the above copyright notice, 
 *  this list of conditions and the following disclaimer in the documentation
 *  and/or other materials provided with the distribution.
 * 
 * Neither the name of Oracle or the names of contributors may 
 * be used to endorse or promote products derived from this software without 
 * specific prior written permission.
 * 
 * This software is provided "AS IS," without a warranty of any kind. ALL 
 * EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, INCLUDING
 * ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
 * OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN MICROSYSTEMS, INC. ("SUN")
 * AND ITS LICENSORS SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY LICENSEE
 * AS A RESULT OF USING, MODIFYING OR DISTRIBUTING THIS SOFTWARE OR ITS
 * DERIVATIVES. IN NO EVENT WILL SUN OR ITS LICENSORS BE LIABLE FOR ANY LOST 
 * REVENUE, PROFIT OR DATA, OR FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, 
 * INCIDENTAL OR PUNITIVE DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY 
 * OF LIABILITY, ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, 
 * EVEN IF SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
 * 
 * You acknowledge that this software is not designed, licensed or intended
 * for use in the design, construction, operation or maintenance of any
 * nuclear facility.
 */
package nl.cwi.swat;

/* Java class to hold static methods which will be called in byte code
 *    injections of all class files.
 */

public class BCITracker {

    /* Master switch that activates methods. */
    
    private static int engaged = 0; 
  
    /* At the very beginning of every method, a call to method_entry() 
     *     is injected.
     */
    
    private static native void _method_entry(Object thr, int cnum, int mnum);
    public static void method_entry(int cnum, int mnum)
    {
	if ( engaged != 0 ) {
	    _method_entry(Thread.currentThread(), cnum, mnum);
	}
    }
    
    /* Before any of the return bytecodes, a call to method_exit() 
     *     is injected.
     */
    
    private static native void _method_exit(Object thr, int cnum, int mnum);
    public static void method_exit(int cnum, int mnum)
    {
	if ( engaged != 0 ) {
	    _method_exit(Thread.currentThread(), cnum, mnum);
	}
    }
    
    /* At each object allocation, a call to newobj() 
     *     is injected.
     */
    
	private static native void _newobj(Object thread, Object o);
	public static void newobj(Object o) {
		if (engaged != 0) {
			_newobj(Thread.currentThread(), o);
		}
	}

    /* At each array allocation, a call to newarr() 
     *     is injected.
     */
	
	private static native void _newarr(Object thread, Object a);
	public static void newarr(Object a) {
		if (engaged != 0) {
			_newarr(Thread.currentThread(), a);
		}
	}

    /*
     * JVMTI 106 : Get Tag
     */
	private static native long _get_tag(Object o);
	public static long getTag(Object o) {
		if (engaged != 0) {
			return _get_tag(o);
		}
		throw new RuntimeException();
	}
	
    /*
     * JVMTI 107 : Set Tag
     */
	private static native void _set_tag(Object o, long tag);
	public static void setTag(Object o, long tag) {
		if (engaged != 0) {
			_set_tag(o, tag);
		} else {
			throw new RuntimeException();
		}
	}
	
//	public static void callbackObjectFreeEvent(long tag) {
//		System.out.println("ObjectFree[" + tag + "]");
//	}

    private static volatile long cachedCount = 1; 

	
	private static native long _get_count();
	public static long getCount() {
		return cachedCount;
	}
	
	private static native long _get_and_increment_count();
	public static long getAndIncrementCount() {
		cachedCount = _get_and_increment_count();
		return cachedCount;
	}
	
}
