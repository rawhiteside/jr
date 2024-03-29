package org.foa.robot;

import java.awt.*;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;
import java.awt.image.BufferedImage;
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.StringSelection;
import java.util.regex.Pattern;
import java.util.Arrays;

import org.foa.ControllableThread;
import org.foa.*;
import org.foa.window.*;

public class ARobot {
	private static final double MOUSE_MOVE_DELAY = 0.01;
	private static final double MOUSE_WHEEL_DELAY = 0.5;
	private Robot m_robot = null;
	private static Toolkit s_toolkit = Toolkit.getDefaultToolkit();
	private static ARobot s_sharedInstance = new ARobot();
	public static Dimension s_screenDim = s_toolkit.getScreenSize();

	public ARobot() {
		// Checked exceptions suck.
		try { m_robot = new Robot(); }
		catch(Exception e) { }
		m_robot.setAutoDelay(1);
		m_robot.setAutoWaitForIdle(true);
	}

	public static ARobot sharedInstance() { return s_sharedInstance; }

	public void tone(int hz, int msecs) {
		try { SoundUtils.tone(hz, msecs); }
		catch(javax.sound.sampled.LineUnavailableException e) { beep(); }
	}

	public void beep() { s_toolkit.beep(); }

	public static boolean isOffScreen(Point pt) { return isOffScreen(pt.x, pt.y); }
	public static boolean isOffScreen(int x, int y) {
		if (x < 0 || y < 0) { return true; }
		Dimension dim = s_screenDim;
		if (x >= dim.width || y >= dim.height) { return true; }
		return false;
	}
	

	public PixelBlock fullScreenCapture() {
		Dimension dim = s_screenDim;
		return screenRectangle(0, 0, dim.width, dim.height);
	}

	public PixelBlock screenRectangle(int x, int y, int width, int height) {
		return screenRectangle(new Rectangle(x, y, width, height));
	}
	public PixelBlock screenRectangle(Rectangle rect) {
		return new PixelBlock(rect);
	}

	public BufferedImage createScreenCapture(Rectangle rect) {
		return m_robot.createScreenCapture(rect);
	}

	public void checkForPause() {
		ControllableThread.checkForPause();
	}

	public void withRobotLock(Runnable r) {robotSync(r);}

	public void claimRobotLock() {
		// Claim the lock.  If we get interrupted, we DID NOT get the lock.
		try {RobotLock.instance().lockInterruptibly();}
		catch(InterruptedException e) {throw new ThreadKilledException();}
	}

	public void releaseRobotLock() {
		RobotLock.instance().unlock();
	}

	public void robotSync(Runnable r) {
		checkForPause();
		claimRobotLock();
		Thread.currentThread().setPriority(Thread.MAX_PRIORITY);

		// Run the runnable, and make sure to release the lock
		try { r.run(); }
		
		finally {
			releaseRobotLock();
			Thread.currentThread().setPriority(Thread.NORM_PRIORITY);
		}
	}

	public Dimension screenSize() {return s_screenDim;}

	/**
	 * Get an int holding the rgb values for screen coordinates [x, y]
	 * @return 0xrrggbb.  Alpha chanel masked away.
	 */
	public int getPixel(int x, int y) {return getPixel(new Point(x, y));}
	public int getPixel(Point p) {
		checkForPause();
		return m_robot.getPixelColor(p.x, p.y).getRGB() & 0xFFFFFF;
	}

	/**
	 * Get a Color holding the rgb values for screen coordinates [x, y]
	 */
	public Color getColor(int x, int y) {return getColor(new Point(x, y));}
	public Color getColor(Point p) {
		checkForPause();
		return m_robot.getPixelColor(p.x, p.y);
	}

	/**
	 * Move the mouse to the provided screen coordinates.
	 */
	public void mm(int x, int y) {mm(x, y, MOUSE_MOVE_DELAY);}
	public void mm(Point p, double delaySecs) {mm(p.x, p.y, delaySecs);}
	public void mm(Point p) {mm(p, MOUSE_MOVE_DELAY);}
	public void mm(int x, int y, double delaySecs) {
		checkForPause();
		m_robot.mouseMove(x, y);
		sleepSec(delaySecs);
	}

	public void mouse_wheel(int ticks) {
		mouse_wheel(ticks, MOUSE_WHEEL_DELAY);
	}

	public void mouse_wheel(int ticks, double delaySecs) {
		int count = ticks;
		int incr = 1;
			
		if(ticks < 0) {
			incr = -1;
			count = -ticks;
		}
		
		for(int i = 0; i < count; i++) {
			checkForPause();
			m_robot.mouseWheel(incr);
			sleepSec(delaySecs);
		}
	}


	/**
	 * Where's the mouse pointer?
	 * @return a Point.
	 */
	public Point mousePos() {
		return MouseInfo.getPointerInfo().getLocation();
	}

	public void mousePress(int button) {
		checkForPause();
		m_robot.mousePress(button);
	}

	public void mouseRelease(int button) {
		m_robot.mouseRelease(button);
	}

	public void rbd() {mousePress(InputEvent.BUTTON3_DOWN_MASK);}
	public void rbu() {mouseRelease(InputEvent.BUTTON3_DOWN_MASK);}
	public void lbd() {mousePress(InputEvent.BUTTON1_DOWN_MASK);}
	public void lbu() {mouseRelease(InputEvent.BUTTON1_DOWN_MASK);}
	public void mbd() {mousePress(InputEvent.BUTTON2_DOWN_MASK);}
	public void mbu() {mouseRelease(InputEvent.BUTTON2_DOWN_MASK);}

	public void xrclickAtRestore(Point p) {xrclickAtRestore(p.x, p.y);}
	public void xrclickAtRestore(int x, int y) {
		checkForPause();
		Point prevPos = mousePos();
		xrclickAt(x, y);
		mm(prevPos.x, prevPos.y);
	}

	public void lclickAtRestore(Point p) {lclickAtRestore(p.x, p.y);}
	public void lclickAtRestore(int x, int y) {
		checkForPause();
		Point prevPos = mousePos();
		lclickAt(x, y);
		mm(prevPos.x, prevPos.y);
	}

	public void xrclickAt(Point p) { xrclickAt(p.x, p.y, MOUSE_MOVE_DELAY); }
	public void xrclickAt(Point p, double delaySec) { xrclickAt(p.x, p.y, delaySec); }

	public void xrclickAt(int x, int y) { xrclickAt(x, y, MOUSE_MOVE_DELAY); }
	public void xrclickAt(int x, int y, double delaySec) {
		claimRobotLock();
		try {
			mm(x, y, delaySec);
			rbd();
			rbu();
		}
		finally {releaseRobotLock();}
	}

	public void lclickAt(Point p) { lclickAt(p.x, p.y, MOUSE_MOVE_DELAY); }
	public void lclickAt(Point p, double delaySec) { lclickAt(p.x, p.y, delaySec); }

	public void lclickAt(int x, int y) { lclickAt(x, y, MOUSE_MOVE_DELAY); }
	public void lclickAt(int x, int y, double delaySec) {
		claimRobotLock();
		try {
			// Something Eldrad said made things work faster/better:
			// release both mouse buttons first.
			rbu(); lbu();
			
			mm(x, y, delaySec);
			lbd();
			lbu();
		}
		finally {releaseRobotLock();}
	}

	public void sleepSec(int secs) {sleepSec((double) secs);}
	public void sleepSec(float secs) {sleepSec((double) secs);}
	public void sleepSec(double secs) { ControllableThread.sleepSec(secs); }

	public void keyPress(int vk)  {keyPress(vk, 0.0);}
	public void keyPress(int vk, double delaySecs)  {
		checkForPause();
		m_robot.keyPress(vk);
		sleepSec(delaySecs);
	}

	public void keyRelease(int vk) {keyRelease(vk, 0.0);}
	public void keyRelease(int vk, double delaySecs) {
		m_robot.keyRelease(vk);
		sleepSec(delaySecs);
	}

	public void sendVk(int key) {sendVk(key, 0.01);}
	public void sendVk(int key, double delaySecs) {
		keyPress(key, delaySecs);
		keyRelease(key);
	}


	// Should clean this up: This method sends via the clipboard.  It
	// can handle any character, but seems to append a newline.  Dunno why.
	//
	// sendString below can send only letters and digits. Maybe some
	// others, but not all.
	public void sendLine(String text) {
		StringSelection stringSelection = new StringSelection(text);
		Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
		clipboard.setContents(stringSelection, stringSelection);
		sleepSec(0.01);
		keyPress(KeyEvent.VK_CONTROL);
		keyPress(KeyEvent.VK_V);
		keyRelease(KeyEvent.VK_V);
		keyRelease(KeyEvent.VK_CONTROL);
	}

	public void sendString(String text) {
		sendString(text, 0.01);
	} 
	public boolean sendString(String s, double delaySeconds) {
		char[] b = s.toCharArray();

		for (char c : b) {
			if(Character.isLowerCase(c) || Character.isDigit(c)) {
				sendVk(Character.toUpperCase(c), delaySeconds);
			} else {
				keyPress(KeyEvent.VK_SHIFT, delaySeconds);
				sendVk(Character.toUpperCase(c), delaySeconds);
				keyRelease(KeyEvent.VK_SHIFT, delaySeconds);
			}
		}
		return true;
	}
}
