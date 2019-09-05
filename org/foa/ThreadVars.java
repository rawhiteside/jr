package org.foa;

/**
 * Thread-local info usable from both Java and Ruby.
 **/

public class ThreadVars {

	public static void set(String key, Object value) {
		Thread t = Thread.currentThread();
		if (t instanceof ControllableThread) {
			ControllableThread ct = (ControllableThread) t;
			ct.threadVars().put(key, value);
		}
	}

	public static Object get(String key) {
		Thread t = Thread.currentThread();
		if (t instanceof ControllableThread) {
			ControllableThread ct = (ControllableThread) t;
			return ct.threadVars().get(key);
		}
		return null;
	}
}
