package org.foa;

public class ThreadKilledException extends RuntimeException {
	public ThreadKilledException() {
		super("Thread killed");
	}
}

