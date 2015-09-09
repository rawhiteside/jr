package org.foa.robot;

import java.util.concurrent.locks.ReentrantLock;

// A singleton ReentrantLock.
// the kinda weird design here results from porting from Ruby.  
public class RobotLock extends ReentrantLock {
    private static RobotLock s_lock = new RobotLock();
    public static RobotLock instance() {
	return s_lock;
    }
}
