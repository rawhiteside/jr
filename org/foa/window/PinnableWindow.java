package org.foa.window;

import org.foa.*;
import org.foa.robot.*;

import java.awt.*;

public class PinnableWindow extends AWindow {
    private boolean m_pinned = false;
    // Timestamp of a click.
    private long m_invalidHeightMillis = 0;
    
    public PinnableWindow(Rectangle rect) {
	super(rect);
	invalidateHeight();
    }

    private void invalidateHeight() {
	m_invalidHeightMillis = System.currentTimeMillis();
    }

    // For a while after a click, we re-check the height.
    private long INVALID_DURATION = 100;
    private boolean isHeightValid() {
	if (m_invalidHeightMillis == 0) {
	    return true;
	}
	if((System.currentTimeMillis() - m_invalidHeightMillis) > INVALID_DURATION) {
	    m_invalidHeightMillis = 0;
	}
	return false;
    }

    public Rectangle getRect() {
	Rectangle rect = super.getRect();
	//
	if(!isHeightValid()) {
	    Rectangle newRect = WindowGeom.confirmHeight(rect);
	    // It only changes once.
	    if (newRect.height != rect.height) {
		rect = newRect;
		setRect(rect);
	    }
	}
	return rect;
    }

    public Insets textInsets() {
	return new Insets(4, 4, 5, 32);
    }

    private static double MIN_DELAY = 0.05;

    // Override to invalidate the height on pinnables. 
    public void dialogClick(Point p, String refreshLoc, double delay) {
	//super.dialogClick(p, refreshLoc, Math.max(delay, MIN_DELAY));
	super.dialogClick(p, refreshLoc, delay);
	invalidateHeight();
    }
    public AWindow clickOn(String menuPath, String refreshLoc) {
	AWindow rv = super.clickOn(menuPath, refreshLoc);
	invalidateHeight();
	return rv;
    }
    public void refresh(String where) {
	super.refresh(where);
	invalidateHeight();
    }	
    
    public boolean getPinned() {return m_pinned;}

    public PinnableWindow pin() {
	Rectangle r = getRect();
	// Pin/unpin don't invalidate height. Thus the super.

	// XXX 10/28/15 delay increased to 0.05, when I saw a kettle window not unpin.
	// XXX Will it help?  I dunno.
	super.dialogClick(new Point(r.width - 20, 20), null, 0.05);
	m_pinned = true;
	return this;
    }

    public void unpin() {
	// Pin/unpin don't invalidate height. Thus the super.

	// XXX 10/28/15 delay increased to 0.05, when I saw a kettle window not unpin.
	// XXX Will it help?  I dunno.
	super.dialogClick(new Point(getRect().width - 20, 20), null, 0.05);
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


    private boolean attemptDrag(Point p, double requested_delay) {
	double delay = Math.max(requested_delay,0.075);
	claimRobotLock();
	try {
	    Rectangle rect = getRect();
	    mm(rect.x, rect.y, delay);
	    rbd();
	    // sleepSec(delay);
	    mm(p, delay);
	    rbu();
	    // sleepSec(delay);
	    return isDialogAt(p);
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
	    if(attemptDrag(p, delay)) {break;}
	    // I've found this print to be helpful.
	    System.out.println("Trying again to drag");
	}

	// Update to the new origin.
	Rectangle r = getRect();
	r.x = p.x;
	r.y = p.y;
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
