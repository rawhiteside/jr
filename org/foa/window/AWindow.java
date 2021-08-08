package org.foa.window;

import org.foa.robot.*;
import org.foa.text.*;
import org.foa.*;

import java.io.File;
import java.awt.*;
import java.awt.event.*;


/**
 * Yes.  I know that the proper relationship of AWindow and ARobot is not *is-a*.
 *
 * But I wanted convenient access to the robot methods, and this was
 * easy.  Maybe I'll turn it into a static import someday.
 *
 */

public abstract class AWindow extends ARobot  {
	private static boolean ALLOW_TEXT_READER_LOG = true;
	private Rectangle m_rect;
	private TextReader m_textReader = null;
	private String m_defaultRefreshLoc = "tl"; 
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

	private WindowGeom m_windowGeom = new LegacyWindowGeom();
	public WindowGeom getWindowGeom() {
		return m_windowGeom;
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


	public void dialogClick(Point p) { dialogClick(p, 0.01); }
	public void dialogClick(Point p, double delay) {
		claimRobotLock();
		try {
			lclickAt(toScreenCoords(p), delay);
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

	// PinnableWindow overrides this to get rid of the pin. 
	public Rectangle textRectangle() {
		return getRect();
	}

	public String getDefaultRefreshLoc() { return m_defaultRefreshLoc; }
	public void setDefaultRefreshLoc(String loc) { m_defaultRefreshLoc = loc; }

	private double m_defaultRefreshDelay = 0.05;
	public double getDefaultRefreshDelay() { return m_defaultRefreshDelay; }
	public void setDefaultRefreshDelay(double delay) { m_defaultRefreshDelay = delay; }


	public void refresh(){ refresh(getDefaultRefreshLoc(), getDefaultRefreshDelay()); }
	public void refresh(double delay){ refresh(getDefaultRefreshLoc(), delay); }
	public void refresh(String where) { refresh(where, getDefaultRefreshDelay()); }

	public void refresh(String where, double delay) {
		Rectangle rect = getRect();
		if (where.equals("tc")) {
			dialogClick(new Point(rect.width / 2, 4), delay);
		} else if (where.equals("tl")) {
			dialogClick(new Point(4, 4), delay);
		} else if (where.equals("tr")) {
			dialogClick(new Point(rect.width - 4, 4), delay);
		} else if (where.equals("lc")) {
			dialogClick(new Point(4, rect.height / 2), delay);
		} else if (where.equals("rc")) {
			dialogClick(new Point(rect.width - 4, rect.height / 2), delay);
		} else {
			throw new RuntimeException("Bad refresh arg: " + where);
		}
		flushTextReader();
		// Needs at least a little time to redisplay.  Thread.yield was not enough.
		// This may be longer than necessary?
		sleepSec(delay);
	}

	public boolean shouldLogReadTextErrors() {
		return true;
	}

	public String readText() {
		TextReader tr = textReader();
		String text = tr.readText(); 
		if (shouldLogReadTextErrors() && ALLOW_TEXT_READER_LOG) { checkText(text, tr); }
		return text;
	}

	// For access from Ruby.  I probably misunderstand something, but
	// I can't get to public static variables.
	public static void setAllowTextReaderLog(boolean allow) {
		ALLOW_TEXT_READER_LOG = allow;
	}
	public static boolean getAllowTextReaderLog() { return ALLOW_TEXT_READER_LOG;}

	private void checkText(String text, TextReader tr) {
		try {
			if (!text.contains(AFont.getUnknownGlyph())) { return; }
			PixelBlock pb = tr.getPixelBlock();
			String prefix = getTextHelper().imagePrefix();
			File f = File.createTempFile(prefix, ".png", new File("./screen-shots"));
			pb.saveImage(f.getPath());
			beep();
		} catch(Exception e) {
			System.out.println("Exception in checkText.");
			e.printStackTrace();
		}
	}

	
	// Default here is Legacy windows.
	public ITextHelper getTextHelper() {
		return new LegacyTextHelper();
	}

	public TextReader textReader() {
		if (m_textReader == null) {
			Rectangle r = textRectangle();
			m_textReader = new TextReader(new PixelBlock(r), getTextHelper());
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
		if(p != null) {lclickAt(p);}
		flushTextReader();
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
		ARobot.sharedInstance().sendVk(KeyEvent.VK_ESCAPE);
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
				// System.out.println(w.readText() + "\n---\n" + menu + "\n--\n");
				Point pt = w.coordsForLine(menu);
				if (pt == null) {
					w = null;
					break;
				}
				if (i >= path.length - 1) { 
					lclickAt(pt, 0.05);
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

	private boolean attemptDrag(Point p, double requested_delay) {
		double delay = Math.max(requested_delay,0.075);
		claimRobotLock();
		try {
			/**
			 * Dialog can change shape on move.  The left center of
			 * the dialog is preserved.  Let's grab that now, then
			 * confirm there's a dialog at the destination.
			 */
			Rectangle rect = getRect();
			Point lcOrig = new Point(rect.x, rect.y + rect.height/2);
			Point lcDest = new Point(lcOrig);
			lcDest.translate(p.x - rect.x, p.y - rect.y);

			mm(rect.x, rect.y, delay);
			lbd();
			mm(p, delay);
			lbu();
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

	public AWindow dragTo(int x, int y) {
		return dragTo(new Point(x, y), 0.0);
	}

	public AWindow dragTo(Point p) {
		return dragTo(p, 0.0);
	}

	public AWindow dragTo(Point p, double delay) {
		for(int i = 0; i < 5; i++) {
			if(attemptDrag(p, delay)) {break;}
		}

		return this;
	}
	/**
	 * See if there's a dialog at the point (after dragging)
	 */
	private boolean isDialogAt(Point p) {
		Point inner = new Point(p.x + 4, p.y);
		Rectangle rect = getWindowGeom().rectFromPoint(inner);
		if(rect == null) { 
			System.out.println("IsDialogPresent: No window at destination.");
			return false; 
		}

		// Make sure the edge is where expected.
		// If looks good, update rectangle
		if (p.x == rect.x) {
			setRect(rect);
			return true;
		} else {
			System.out.println("IsDialogPresent: Wrong window at destination.");
			return false;
		}
	
	}

}
