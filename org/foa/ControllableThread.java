package org.foa;
import java.util.concurrent.locks.ReentrantLock;

/**
 * This class should be used by JRuby threads instead of the bare
 * Thread.
 *
 * It gives the ability to pause and unpause *all* of the threads.
 * This relies on all of the threads periodically calling
 * checkForPause(), which the Robot does.  The pauseAll() and
 * resumeAll() methods are called (currently) from jrobot-pause.rb.
 * This watches the NUMLOCK key.  If it's lit up, then the robot
 * runs.  If it's off, the robot pauses.
 *
 * Further, it implements a "kill" method on threads that's safe (I
 * hope!  It's a very nasty problem).
 * 
 */
public class ControllableThread extends Thread {
    private static ReentrantLock s_pauseLock = new ReentrantLock();
    boolean m_killed = false;

    public ControllableThread(Runnable runnable) {
	super(runnable);
	start();
    }
    public ControllableThread(String name, Runnable runnable) {
	super(runnable, name);
	start();
    }
    public void kill() {
	m_killed = true;
	interrupt();
    }

    public static void pauseAll() {
	s_pauseLock.lock();
    }

    public static void resumeAll() {
	s_pauseLock.unlock();
    }

    public static void checkForPause() {

	if(!(Thread.currentThread() instanceof ControllableThread)) { return; }

	if(((ControllableThread)Thread.currentThread()).m_killed) {
	    throw new ThreadKilledException();
	}
	try {
	    s_pauseLock.lockInterruptibly();
	    s_pauseLock.unlock();
	} catch(Exception e) {
	    throw new ThreadKilledException();
	}
    }

    public static void sleepSec(int seconds) {
	sleepSec((double)seconds);
    }

    public static void sleepSec(float seconds) {
	sleepSec((double)seconds);
    }

    public static void sleepSec(double seconds) {
	checkForPause();
	try {
	    Thread.sleep((int)(1000 * seconds));
	} catch(Exception e) {
	    throw new ThreadKilledException();
	}
    }
}
