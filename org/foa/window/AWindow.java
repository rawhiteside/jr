package org.foa.window;

import org.foa.robot.*;
import org.foa.text.*;
import org.foa.*;

import java.awt.*;
import java.awt.event.*;


/**
 * Yes.  I know that the proper relationship of AWindow and ARobot is not *is-a*.
 *
 * But I wanted convenient access to the robot methods, and this was
 * easy.  Maybe I'll turn it into a static import someday.
 *
 */

public abstract class AWindow extends ARobot implements ITextHelper {
	private Rectangle m_rect;
	private TextReader m_textReader = null;
	private String m_defaultRefreshLoc = "lc"; 
	private String m_notation = null;  // An extra note for use as needed.

	public AWindow() {
		super();
	}
	public AWindow(Rectangle rect) {
		this();
		setRect(rect);
	}

	// Just a note that can be attached to the window as needed.
	public void setNotation(String note) {
		m_notation = note;
	}
	public String getNotation() {
		return m_notation;
	}

	public void setRect(Rectangle rect) { 
		m_rect = rect; 
		if (rect == null) {
			throw new RuntimeException("Null rectangle. ");
		}
	}
	public Rectangle getRect() { return new Rectangle(m_rect); }


	public Point toScreenCoords(Point p) {
		Rectangle rect = getRect();
		return new Point(p.x + rect.x, p.y + rect.y);
	}

	public Point toDialogCoords(Point p) {
		Rectangle rect = getRect();
		return new Point(p.x - rect.x, p.y - rect.y);
	}


	public void dialogClick(Point p) { dialogClick(p, null); }
	public void dialogClick(Point p, String refreshLoc) { dialogClick(p, refreshLoc, 0.01); }
	public void dialogClick(Point p, String refreshLoc, double delay) {
		claimRobotLock();
		try {
			if (refreshLoc != null) {
				refresh(refreshLoc);
			}
			rclickAt(toScreenCoords(p), delay);
		}
		catch(ThreadKilledException e) { throw e; }
		catch(Exception e) {
			System.out.println("Exception: in dialogClick" + e.toString());
			e.printStackTrace();
			throw e;
		}
		finally {releaseRobotLock();}
	}


	public int dialogPixel(Point p){ return getPixel(toScreenCoords(p)); }

	public Color dialogColor(Point p) { return getColor(toScreenCoords(p)); }

	// This used to do something. XXX
	public Rectangle textRectangle() {
		return getRect();
	}

	public String getDefaultRefreshLoc() { return m_defaultRefreshLoc; }
	public void setDefaultRefreshLoc(String loc) { m_defaultRefreshLoc = loc; }


	public void refresh(){
		refresh(getDefaultRefreshLoc()); 
	}
	public void refresh(String where) {
		Rectangle rect = getRect();
		if (where.equals("tc")) {
			dialogClick(new Point(rect.width / 2, 4));
		} else if (where.equals("tl")) {
			dialogClick(new Point(4, 4));
		} else if (where.equals("tr")) {
			dialogClick(new Point(rect.width - 4, 4));
		} else if (where.equals("lc")) {
			dialogClick(new Point(4, rect.height / 2));
		} else if (where.equals("rc")) {
			dialogClick(new Point(rect.width - 4, rect.height / 2));
		} else {
			throw new RuntimeException("Bad refresh arg: " + where);
		}
		flushTextReader();
		// Needs at least a little time to redisplay.  Thread.yield was not enough.
		// This may be longer than necessary?
		sleepSec(0.05);
	}

	private static int RMIN = 0xca;
	private static int GMIN = 0xb4;
	private static int BMIN = 0x81;
	private int m_spacePixelCount = 4;
	// ITextHelper methods.
	public boolean isInk(Color c) {
		//if (Math.abs(c.getRed() - c.getGreen()) < 25 || Math.abs(c.getGreen() - c.getBlue()) < 25) 
		//	{
		//		return true
		//	}
			
		if (c.getRed() < RMIN || c.getGreen() < GMIN || c.getBlue() < BMIN) {
			return true;
		} else {
			return false;
		}
	}

	public void setSpacePixelCount(int count) {
		m_spacePixelCount = count;
	}

	public int spacePixelCount() {
		return m_spacePixelCount;
	}

	public String readText() 
	{ 
		return textReader().readText(); 
	}

	public TextReader textReader() {
		if (m_textReader == null) {
			Rectangle r = textRectangle();
			m_textReader = new TextReader(r, this);
		}
		return m_textReader;
	}


	public void flushTextReader() { m_textReader = null; }

	
	public String textColor(String s) {
		return textReader().textColor(s);
	}

	/**
	 * Wait (for the provided duration) for the supplied text to
	 * appear in a window. Refresh until it does.  Returns whether it
	 * appeared.
	 */
	public boolean waitForText(String text)  {
		return waitForText(text, 1.0);
	}
	public boolean waitForText(String text, double maxSeconds) {
		long start = System.currentTimeMillis();
		while(true) {
			refresh("lc");
			if(readText().indexOf(text) != -1) {
				return true;
			}
			sleepSec(0.1);
			if(maxSeconds < (System.currentTimeMillis() - start) * 1000) {
				return false;
			}
		}
	}

	public Point clickWord(String word) {
		Point p = coordsForWord(word);
		if(p != null) {rclickAt(p);}
		return p;
	}

	// Return a point to click on the provided word.
	public Point coordsForWord(String word) {
		return textReader().pointForWord(word);
	}
	
	// Return a point to click on a line starting with the provided
	// text.
	public Point coordsForLine(String menu) {
		return textReader().pointForLine(menu);
	}

	public static void dismissAll() {
		final ARobot robot = new ARobot();
		// A more or less random point that should be on everyone's screen.
		final Point p = new Point(230, 600);
		// Now, search left/up until we find a non-border pixel
		while(WindowGeom.isOuterBorder(robot.getColor(p))) {
			p.x -= 1;
			p.y -= 1;
			if (p.x == 0 || p.y == 0) {
				throw new RuntimeException("Didn't find a non-border pixel");
			}
		}
		robot.withRobotLock(new Runnable() {
				public void run() {
					// Force a delay.  We're probably here because things are laggy.
					robot.mm(p, 0.1);
					robot.sendVk(KeyEvent.VK_ESCAPE);
					// Now, look to see if the pixel is now a border
					// This happens when there wasn't anything to dismiss, so the
					// self menu appeared.  If so, dismiss that.
					robot.mm(p, 0.1);
					if (WindowGeom.isOuterBorder(robot.getColor(p))) {
						robot.sendVk(KeyEvent.VK_ESCAPE);
					}
				}
			});
	}

	/**
	 * Click on the first line that matches.
	 * Returns the last window manipulated on success, nil on failure
	 */
	public AWindow clickOn(String menuPath) { return clickOn(menuPath, null); }
	public AWindow clickOn(String menuPath, String refreshLoc) {
		boolean windowPopped = false;
		AWindow w = this;
		String[] path = menuPath.split("/");
		claimRobotLock();
		if(refreshLoc != null) {
			w.refresh(refreshLoc);
		}
		try {
			for(int i = 0; i < path.length; i++) {
				if(w == null) { break; }
				String menu = path[i];
				Point pt = w.coordsForLine(menu);
				if (pt == null) {
					w = null;
					break;
				}
				if (i >= path.length - 1) { 
					rclickAt(pt, 0.05);
				}
				else {
					w = PinnableWindow.fromScreenClick(pt);
				}
				windowPopped = true;
			}
			// Is there a dangling window up still?
			// That happens when we've popped a submenu, but then didn't find
			// the thing to click on there.
			if(w == null && windowPopped) { AWindow.dismissAll(); }

		}
		catch(ThreadKilledException e) { throw e; }
		catch(Exception e) {
			System.out.println("Exception: in clickOn" + e.toString());
			e.printStackTrace();
			throw e;
		}
		finally {releaseRobotLock();}
		return w;
	}
	
	public void displayToUser(String title) {
		ImagePanel.displayImage(createScreenCapture(textRectangle()), title);
	}
}
