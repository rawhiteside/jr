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
	if(!isDialogAt(r.x, r.y)) {
	    throw new RuntimeException("No dialog to pin at (" + r.x + ", " + r.y + ")");
	}
	dialogClick(new Point(r.width - 20, 20));
	if(!isDialogAt(r.x, r.y)) {
	    throw new RuntimeException("No dialog after pin at (" + r.x + ", " + r.y + ")");
	}
	m_pinned = true;
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
	// Left over from when pixels were expensive.  Fix this.
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
	r = new Rectangle(x, y, r.width + 1, r.height + 1);
	PixelBlock pb = new PixelBlock(r);
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

    private void attemptDrag(Point p) {
	Rectangle r = getRect();

	double delay = 0.05;
	claimRobotLock();
	try {
	    mm(r.x, r.y);
	    sleepSec(delay);
	    rbd();
	    sleepSec(delay);
	    mm(p);
	    sleepSec(delay);
	    rbu();
	    // Sometimes it moves slowly?
	    sleepSec(delay);
	}
	finally {releaseRobotLock();}
    }

    public PinnableWindow dragTo(Point p) {

	while(true) {
	    attemptDrag(p);
	    if(isDialogAt(p)) {
		break;
	    }
	    // I've found this print to be helpful.
	    System.out.println("Trying again to drag");
	}
	Rectangle r = getRect();
	r.x = p.x;
	r.y = p.y;
	if (!getStable()) { reconfirmHeight(); }
	setRect(r);
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
		robot.mm(pt, 0.1);
		robot.rclickAt(pt, 0.05);
		robot.sleepSec(0.1);
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
		System.out.println("Trying agin to pop a window.");
	    }
	} finally { robot.releaseRobotLock(); }

	return win;
    }
}
