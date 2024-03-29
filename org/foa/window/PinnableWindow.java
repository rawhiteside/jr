package org.foa.window;

import org.foa.*;
import org.foa.robot.*;
import org.foa.text.ITextHelper;

import java.awt.*;

public class PinnableWindow extends AWindow {
	// Currently pinned?
	private boolean m_pinned = false;

	// Is the window size unchanging?
	private boolean m_static = false;

	public PinnableWindow(Rectangle rect) {
		super(rect);
	}

	public boolean isStaticSize() {
		return m_static;
	}
	public void setStaticSize(boolean value) {
		m_static = value;
	}

	private WindowGeom m_windowGeom = new PinnableWindowGeom();
	public WindowGeom getWindowGeom() {
		return m_windowGeom;
	}
	// Default here is Legacy windows.
	public ITextHelper getTextHelper() {
		return new PinnableTextHelper();
	}

	// Reduce width to exclude the pin. 
	public Rectangle textRectangle() {
		Rectangle rect = getRect();
		rect.width -= 25;
		return rect;
	}

	/**
	 * Basically, any mouse click can now change the window bounds.
	 * The left top seems to be preserved.
	 */
	private void updateRect() {
		if (m_static) {return;}

		sleepSec(0.08);
		Rectangle r = getRect();
		int x = r.x + 4;
		int y = r.y + 4;
		Rectangle rnew = getWindowGeom().rectFromPoint(new Point(x, y));
		if (rnew != null) {
			setRect(rnew);
		}
	}

	public void dialogClick(Point p, double delay) {
		dialogClick(p, delay, false);
	}

	public void dialogClick(Point p, double delay, boolean unpin) {
		claimRobotLock();
		try {
			super.dialogClick(p, delay);
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
		dialogClick(new Point(r.width - 20, 20), 0.01);
		m_pinned = true;
		return this;
	}

	public void unpin() {
		updateRect();
		// Changed the default unpin delay from 0.01 to 0.02.  Rare
		// failures to unpin. Maybe this fixes?  I dunno.
		dialogClick(new Point(getRect().width - 20, 20), 0.02, true);
		m_pinned = false;
	}

	public void unpin(double delay) {
		updateRect();
		dialogClick(new Point(getRect().width - 20, 20), delay, true);
		m_pinned = false;
	}


	public static PinnableWindow fromPoint(int x, int y) {
		return fromPoint(new Point(x, y));
	}

	public static PinnableWindow fromPoint(Point p) {
		Rectangle rect = new PinnableWindowGeom().rectFromPoint(p);
		if (rect == null) {
			return null;
		} else {
			return new PinnableWindow(rect);
		}
	}



	public static PinnableWindow fromScreenClick(int x, int y) {
		return fromScreenClick(new Point(x, y));
	}

	public static PinnableWindow fromScreenClick(Point pt) {
		PinnableWindow win = null;
		ARobot robot = new ARobot();

		// Maybe we're clicking on a window, expecting a menu.  Get
		// the undeerlying window rect, so we can tell when a *new*
		// window pops.  We might, instead, click, then just detect
		// the original one, thinking it's new.  Maybe this is null.
		WindowGeom windowGeom = new PinnableWindowGeom();
		Rectangle rectTarget = windowGeom.rectFromPoint(pt);

		robot.claimRobotLock();
		try {
			double postDismissDelay = 0.0;
			double delay = 0.05;
			// May need to try several times.
			for(int kk = 0; kk < 2; kk++) {
				robot.mm(new Point(pt.x, pt.y - 1), delay);
				robot.sleepSec(postDismissDelay);
				robot.mm(pt, delay);
				postDismissDelay = 0.0;
				robot.lclickAt(pt, delay);
				robot.sleepSec(delay);
				// Now, give it at most a half-second to appear.
				Rectangle rectangle = null;
				long startMillis = System.currentTimeMillis();
				for(int i = 0; i < 50; i++) {
					Point inside = new Point(pt.x + 4, pt.y + 4);
					rectangle = windowGeom.rectFromPoint(inside);
					//
					// Did we find a window?
					if (rectangle != null) {
						//
						// Maybe we were clicking on a window, and we
						// found *that*.
						//
						// If we weren't clicking on a window, the we
						// found the new one.
						if(rectTarget == null) { break; }
						//
						// If the one we found is different than the
						// one we clicked on, then we found the new
						// one.
						if(!rectTarget.equals(rectangle)) {
							break;
						}
						// ... otherwise wait for popped window.
					}

					// Has it been too long?
					long elapsed = System.currentTimeMillis() - startMillis;
					if (elapsed > 500) { break; }
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
