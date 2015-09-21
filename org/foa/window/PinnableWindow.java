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
    public boolean isDialogAt(int x, int y) {
	Rectangle r = getRect();
	// XXX Left over from when pixels were expensive.  Fix this.
	Point[] probes = new Point[] {
	    new Point(x, y),
	    new Point(x + r.width, y),
	    new Point(x, y + r.height),
	    new Point(x+1, y),
	    new Point(x+2, y), 
	    new Point(x+3, y), 
	    new Point(x+4, y), 
	    new Point(x+5, y), 
	    new Point(x, y+5), 
	    new Point(x, y+6), 
	    new Point(x, y+7), 
	    new Point(x, y+8), 
	    new Point(x, y+9), 
	};
	Rectangle screenRect = new Rectangle(x, y, r.width + 1, r.height + 1);
	PixelBlock pb = new PixelBlock(screenRect);

	for(Point p : probes) {
	    if (pb.pixelFromScreen(p) != 0) {
		return false;
	    }
	}
	return true;
    }

    public static PinnableWindow fromPoint(Point p) {
	Rectangle rect = WindowGeom.rectFromPoint(p);
	if (rect == null) {
	    return null;
	} else {
	    return new PinnableWindow(rect);
	}
    }

    /**
     * Handle the fact that the window might change height upon button down. 
     */
    private void startDragging(double delay) {
	while(true) {
	    mm(m_rect.x, m_rect.y);
	    sleepSec(delay);
	    rbd();
	    sleepSec(delay);
	    Rectangle r = new Rectangle(m_rect);
	    new WindowGeom().confirmHeight(r);
	    // If it changed size, release button, and
	    if(m_rect.equals(r)) {
		return;
	    } else {
		// Release the button, update the rect, and try again.
		System.out.println("startDragging:  retrying.");
		rbu();
		m_rect = r;
	    }
	}
	
    }

    private void attemptDrag(Point p, double requested_delay) {
	double delay = Math.max(requested_delay,0.075);
	claimRobotLock();
	try {

	    // Method here, because the window might resize on button
	    // down.
	    startDragging(delay);

	    mm(p);
	    sleepSec(delay);
	    rbu();
	    // Sometimes it moves slowly?
	    sleepSec(delay);
	    Rectangle r = getRect();
	    r.x = p.x;
	    r.y = p.y;
	    setRect(r);
	    reconfirmHeight();
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
	while(true) {
	    attemptDrag(p, delay);
	    sleepSec(Math.max(delay, 0.1)); // MAGIC NUMBER.  On rare occasions, this is needed.
	    if(isDialogAt(p)) {
	    	break;
	    }
	    // I've found this print to be helpful.
	    System.out.println("Trying again to drag");
	}

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
	    while (true) {
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
