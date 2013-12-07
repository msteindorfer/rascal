package org.eclipse.imp.pdb.values.benchmarks;

import org.junit.runner.JUnitCore;
import org.junit.runner.Request;

/* 
 * Source: http://stackoverflow.com/questions/9288107/run-single-test-from-a-junit-class-using-command-line
 */
public class SingleJUnitTestRunner {
	public static void main(String... args) throws ClassNotFoundException {
		String[] classAndMethod = args[0].split("#");
		Request request = Request.method(Class.forName(classAndMethod[0]),
				classAndMethod[1]);

		new JUnitCore().run(request);
	}
}
