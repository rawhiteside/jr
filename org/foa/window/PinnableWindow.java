package org.foa.window;

import org.foa.*;
import org.foa.robot.*;

import java.awt.*;

public class PinnableWindow extends AWindow {
    private boolean m_pinned = false;
    
    public PinnableWindow(Rectangle rect) {
	super(rect);
    }

    public Insets textInsets() {
	return new Insets(4, 4, 5, 32);
    }

    public boolean getPinned() {return m_pinned;}

    public PinnableWindow pin() {
	Rectangle r = getRect();
	// Pinning doesn't trigger a resize.
	boolean prev = getStable();
	setStable(true);
	dialogClick(new Point(r.width - 20, 20));
	m_pinned = prev;
	setStable(false);
	return this;
    }

    public void unpin() {
	dialogClick(new Point(getRect().width - 20, 20));
	m_pinned = false;
    }

    public boolean isDialogAt(Point p) {
	return isDialogAt(p.x, p.y);
    }
    /**
     * The dialog may have changed height, so don't use top or bottom
     * pixels to decide if the dialog is present.
     * 
     * Check the right and left borders along the center of the
     * dialog.  That's presereved under resize.
     */
    public boolean isDialogAt(int x, int y) {
	Rectangle r = getRect();
	// Set y to the central line of the dialog, and grab that line
	// from the screen.
	y +=  r.height/2;
	Rectangle screenRect = new Rectangle(x, y, r.width + 1, 1);
	PixelBlock pb = new PixelBlock(screenRect);
	
	return (pb.pixelFromScreen(x, y) == 0 &&
		pb.pixelFromScreen(x + 3, y) == 0 &&
		pb.pixelFromScreen(x + r.width, y) == 0 &&
		pb.pixelFromScreen(x + r.width - 3, y) == 0 &&
		pb.pixelFromScreen(x + r.width - 1, y) == WindowGeom.OUTER_BROWN &&
		pb.pixelFromScreen(x + 1, y) == WindowGeom.OUTER_BROWN);
    }

    public static PinnableWindow fromPoint(Point p) {
	Rectangle rect = WindowGeom.rectFromPoint(p);
	if (rect == null) {
	    return null;
	} else {
	    return new PinnableWindow(rect);
	}
    }


    private void attemptDrag(Point p, double requested_delay) {
	double delay = Math.max(requested_delay,0.075);
	claimRobotLock();
	try {
	    mm(m_rect.x, m_rect.y);
	    sleepSec(delay);
	    rbd();
	    sleepSec(delay);
	    mm(p);
	    sleepSec(delay);
	    rbu();
	    sleepSec(delay);
	}
	catch(ThreadKilledException e) { throw e; }
	catch(Exception e) {
	    System.out.println("Exception: in attemptDrag" + e.toString());
	    e.printStackTrace();
	    throw e;
	}
	finally {releaseRobotLock();}
    }

    public PinnableWindow dragTo(Point p) {
	return dragTo(p, 0.0);
    }

    public PinnableWindow dragTo(Point p, double delay) {
	for(int i = 0; i < 5; i++) {
	    attemptDrag(p, delay);
	    if(isDialogAt(p)) { break; }
	    // I've found this print to be helpful.
	    System.out.println("Trying again to drag");
	}

	// Update to the new origin.
	Rectangle r = getRect();
	r.x = p.x;
	r.y = p.y;
	setRect(r);

	// See if the window changed height. 
	if (!getStable()) { reconfirmHeight(); }

	return this;
    }

    public static PinnableWindow fromScreenClick(int x, int y) {
	return fromScreenClick(new Point(x, y));
    }

    public static PinnableWindow fromScreenClick(Point pt) {
	PinnableWindow win = null;
	ARobot robot = new ARobot();
	robot.claimRobotLock();
	try {
	    // May need to try several times.
	    for(int kk = 0; kk < 5; kk++) {
		robot.mm(pt, 0.05);
		robot.rclickAt(pt, 0.05);
		robot.sleepSec(0.05);
		// Now, give it at most a half-second to appear.
		Rectangle rectangle = null;
		long startMillis = System.currentTimeMillis();
		for(int i = 0; i < 50; i++) {
		    rectangle = WindowGeom.rectFromPoint(pt);
		    // Did we find it?
		    if (rectangle != null) {
			break;
		    }
		    // Has it been too long?
		    long elapsed = System.currentTimeMillis() - startMillis;
		    if (elapsed > 500) {
			break;
		    }
		    robot.sleepSec(0.01);
		}
		if (rectangle != null) {
		    // XXX need a better factory scheme, so we can get subclasses.
		    win = new PinnableWindow(rectangle);
		    break;
		}
		// OK, something weird. The window pops in a remote place sometimes.
		// Dismiss all, and try again.
		AWindow.dismissAll();
		robot.sleepSec(0.1);
		System.out.println("Trying again to pop a window.");
	    }
	}
	catch(ThreadKilledException e) { throw e; }
	catch(Exception e) {
	    System.out.println("Exception: in clickOn" + e.toString());
	    e.printStackTrace();
	    throw e;
	}
	finally { robot.releaseRobotLock(); }

	return win;
    }
}
