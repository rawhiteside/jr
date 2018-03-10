package org.foa.window;

import org.foa.*;
import org.foa.robot.*;

import java.awt.*;

public class PinnableWindow extends AWindow {
    private boolean m_pinned = false;
    // Timestamp of a click.
    
    public PinnableWindow(Rectangle rect) {
	super(rect);
    }


    /**
     * Basically, any mouse click can now change the window bounds.
     * The left center seems to be preserved.
     */
    private void updateRect() {
	sleepSec(0.08);
	Rectangle r = getRect();
	int x = r.x + 2;
	int y = r.y + r.height/2;
	Rectangle rnew = WindowGeom.rectFromPoint(new Point(x, y));
	if (rnew == null) {
	    // System.out.println("Update rect failed.");
	    /*
	    Rectangle rect = getRect();
	    PixelBlock pb = new PixelBlock(rect);
	    ImagePanel.displayImage(pb.bufferedImage(), "Update rect failed.");
	    throw new RuntimeException("Update rect failed. ");
	    */
	} else {
	    setRect(rnew);
	}
    }

    public Insets textInsets() {
	return new Insets(4, 4, 5, 32);
    }

    private static double MIN_DELAY = 0.05;

    public void dialogClick(Point p, String refreshLoc, double delay) {
	dialogClick(p, refreshLoc, delay, false);
    }

    public void dialogClick(Point p, String refreshLoc, double delay, boolean unpin) {
	claimRobotLock();
	try {
	    super.dialogClick(p, refreshLoc, delay);
	    if (!unpin) {updateRect();}
	}
	catch(ThreadKilledException e) { throw e; }
	catch(Exception e) {
	    System.out.println("Exception: in dialogClick" + e.toString());
	    e.printStackTrace();
	    throw e;
	}
	finally {releaseRobotLock();}

    }
    public AWindow clickOn(String menuPath, String refreshLoc) {
	AWindow rv = null;
	claimRobotLock();
	try {
	    rv = super.clickOn(menuPath, refreshLoc);
	    updateRect();
	}
	catch(ThreadKilledException e) { throw e; }
	catch(Exception e) {
	    System.out.println("Exception: in clickOn" + e.toString());
	    e.printStackTrace();
	    throw e;
	}
	finally {releaseRobotLock();}

	return rv;
    }

    public void refresh(String where) {
	claimRobotLock();
	try {
	    super.refresh(where);
	    updateRect();
	}
	catch(ThreadKilledException e) { throw e; }
	catch(Exception e) {
	    System.out.println("Exception: in refresh" + e.toString());
	    e.printStackTrace();
	    throw e;
	}
	finally {releaseRobotLock();}
    }	
    
    public boolean getPinned() {return m_pinned;}

    public PinnableWindow pin() {
	Rectangle r = getRect();
	dialogClick(new Point(r.width - 20, 20), null, 0.05);
	m_pinned = true;
	return this;
    }

    public void unpin() {
	updateRect();
	dialogClick(new Point(getRect().width - 20, 20), null, 0.05, true);
	m_pinned = false;
    }

    /**
     * See if there's a dialog at the point (after dragging)
     */
    private boolean isDialogAt(Point p) {
	Rectangle rect = WindowGeom.rectFromPoint(p);
	if(rect == null) { return false; }

	// Make sure the edge is not far away from expected.
	// If looks good, update rectangle
	if (Math.abs(p.x - rect.x) <= 2) {
	    setRect(rect);
	    return true;
	} else {
	    return false;
	}
	
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
	    /**
	     * Dialog can change shape on move.  The left center of
	     * the dialog is preserved.  Let's grab that noe, then
	     * confirm there's a dialog at the destination.
	     */
	    Rectangle rect = getRect();
	    Point lcOrig = new Point(rect.x, rect.y + rect.height/2);
	    Point lcDest = new Point(lcOrig);
	    lcDest.translate(p.x - rect.x, p.y - rect.y);

	    mm(rect.x, rect.y, delay);
	    rbd();
	    // sleepSec(delay);
	    mm(p, delay);
	    rbu();
	    sleepSec(delay);
	    return isDialogAt(lcDest);
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
	    double postDismissDelay = 0.0;
	    double delay = 0.05;
	    // May need to try several times.
	    for(int kk = 0; kk < 5; kk++) {
		robot.mm(new Point(pt.x, pt.y - 1), delay);
		robot.sleepSec(postDismissDelay);
		robot.mm(pt, delay);
		postDismissDelay = 0.0;
		robot.rclickAt(pt, delay);
		robot.sleepSec(delay);
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
		postDismissDelay = 0.1;
		System.out.println("Trying again to pop a window.");
		delay = kk * delay;
	    }
	}
	catch(ThreadKilledException e) { throw e; }
	catch(Exception e) {
	    System.out.println("Exception: in fromScreenClick" + e.toString());
	    e.printStackTrace();
	    throw e;
	}
	finally { robot.releaseRobotLock(); }

	return win;
    }
}
