package org.foa.robot;

import java.awt.*;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;
import java.awt.image.BufferedImage;
import java.util.regex.Pattern;
import java.util.Arrays;

import org.foa.ControllableThread;
import org.foa.*;

public class ARobot {
    private Robot m_robot = null;
    private Toolkit m_toolkit = Toolkit.getDefaultToolkit();

    public ARobot() {
	// Checked exceptions suck.
	try { m_robot = new Robot(); }
	catch(Exception e) { }
    }

    public PixelBlock screenRectangle(int x, int y, int width, int height) {
	return screenRectangle(new Rectangle(x, y, width, height));
    }
    public PixelBlock screenRectangle(Rectangle rect) {
	checkForPause();
	return new PixelBlock(rect);
    }

    public BufferedImage createScreenCapture(Rectangle rect) {
	//return Win32ScreenCapture.getScreenshot(rect);
	return m_robot.createScreenCapture(rect);
    }

    public static void checkForPause() {
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

	// Run the runnable, amd make sure to release the lock
	try { r.run(); }
	catch (Exception e) {
	    System.out.println("Exception: " + e.toString());
	    e.printStackTrace();
	    throw new ThreadKilledException();
	}
	finally {releaseRobotLock();}
    }

    public Dimension screenSize() {return m_toolkit.getScreenSize();}

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
     * Get an color holding the rgb values for screen coordinates [x, y]
     */
    public Color getColor(int x, int y) {return getColor(new Point(x, y));}
    public Color getColor(Point p) {
	checkForPause();
	return m_robot.getPixelColor(p.x, p.y);
    }

    /**
     * Move the mouse to the provided screen coordinates.
     */
    public void mm(int x, int y) {mm(x, y, 0.0);}
    public void mm(Point p, double delaySecs) {mm(p.x, p.y, delaySecs);}
    public void mm(Point p) {mm(p, 0.0);}
    public void mm(int x, int y, double delaySecs) {
	checkForPause();
	m_robot.mouseMove(x, y);
	sleepSec(delaySecs);
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

    public void rclickAtRestore(Point p) {rclickAtRestore(p.x, p.y);}
    public void rclickAtRestore(int x, int y) {
	Point prevPos = mousePos();
	rclickAt(x, y);
	mm(prevPos.x, prevPos.y);
    }

    public void rclickAt(Point p) { rclickAt(p.x, p.y); }
    public void rclickAt(Point p, double delaySec) { rclickAt(p.x, p.y, delaySec); }

    public void rclickAt(int x, int y) { rclickAt(x, y, 0.01); }
    public void rclickAt(int x, int y, double delaySec) {
	claimRobotLock();
	try {
	    mm(x, y, delaySec);
	    rbd();
	    sleepSec(delaySec);
	    rbu();
	    sleepSec(delaySec);
	}
	finally {releaseRobotLock();}
    }

    public void lclickAt(Point p) { lclickAt(p.x, p.y); }
    public void lclickAt(Point p, double delaySec) { lclickAt(p.x, p.y, delaySec); }

    public void lclickAt(int x, int y) { lclickAt(x, y, 0.01); }
    public void lclickAt(int x, int y, double delaySec) {
	claimRobotLock();
	try {
	    mm(x, y, delaySec);
	    lbd();
	    sleepSec(delaySec);
	    lbu();
	    sleepSec(delaySec);
	}
	finally {releaseRobotLock();}
    }


    public void sleepSec(int secs) {sleepSec((double) secs);}
    public void sleepSec(float secs) {sleepSec((double) secs);}
    public void sleepSec(double secs) { ControllableThread.sleepSec(secs); }

    public void keyPress(int vk)  {keyPress(vk, 0.0);}
    public void keyPress(int vk, double delaySecs)  {
	ControllableThread.checkForPause();
	m_robot.keyPress(vk);
	sleepSec(delaySecs);
    }

    public void keyRelease(int vk) {keyRelease(vk, 0.0);}
    public void keyRelease(int vk, double delaySecs) {
	m_robot.keyRelease(vk);
	sleepSec(delaySecs);
    }

    public void sendVk(int key) {sendVk(key, 0.0);}
    public void sendVk(int key, double delaySecs) {
	keyPress(key, delaySecs);
	keyRelease(key, delaySecs);
    }

    public void sendString(String s) {sendString(s, 0.0);}
    public void sendString(String s, double delaySeconds) {
	char[] b = s.toCharArray();
	for (char c : b) {
	    if(Character.isLetterOrDigit(c)){
		if(Character.isLowerCase(c) || Character.isDigit(c)) {
		    sendVk(Character.toUpperCase(c), delaySeconds);
		} else {
		    keyPress(KeyEvent.VK_SHIFT, delaySeconds);
		    sendVk(Character.toUpperCase(c), delaySeconds);
		    keyRelease(KeyEvent.VK_SHIFT, delaySeconds);
		}
	    } else {
		// XXX deal with other characters.
	    }
	}
    }
}
