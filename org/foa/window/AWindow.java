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

public abstract class AWindow extends ARobot  {
    protected Rectangle m_rect;
    private boolean m_stable;
    private TextReader m_textReader = null;

    public AWindow() {
	super();
	m_stable = false;
    }
    public AWindow(Rectangle rect) {
	this();
	setRect(rect);
    }

    // TRIED 0.01.  Too low
    private static double MAGIC_RECONFIRM_DELAY = 0.1;
    public void reconfirmHeight() {
	sleepSec(MAGIC_RECONFIRM_DELAY);
	new WindowGeom().confirmHeight(m_rect);
    }

    public abstract Insets textInsets();

    public void setRect(Rectangle rect) { m_rect = rect; }
    public Rectangle getRect() { return new Rectangle(m_rect); }


    public Point toScreenCoords(Point p) {
	return new Point(p.x + m_rect.x, p.y + m_rect.y);
    }

    // "Stable" means that you know that, at least for the moment, the
    // window will not change size upon click.
    public void setStable(boolean b) { m_stable = b; }
    public boolean getStable() { return m_stable; }

    public void dialogClick(Point p) { dialogClick(p, 0.01); }
    public void dialogClick(Point p, double delay) {
	Point point = toScreenCoords(p);
	claimRobotLock();
	try {
	    rclickAt(point, delay);
	    if (!getStable()) {
		reconfirmHeight();
	    }
	}
	finally {releaseRobotLock();}
    }


    public int dialogPixel(Point p){ return getPixel(toScreenCoords(p)); }

    public Color dialogColor(Point p) {
	Point point = toScreenCoords(p);
	return getColor(point);
    }

    public Rectangle textRectangle() {
	Insets margin = textInsets();
	return new Rectangle(m_rect.x + margin.left,
			     m_rect.y + margin.top,
			     m_rect.width - margin.left - margin.right,
			     m_rect.height - margin.top - margin.bottom);
    }


    public void refresh(){ refresh("tc"); }
    public void refresh(String where) {
	if (where.equals("tc")) {
	    dialogClick(new Point(m_rect.width / 2, 2));
	} else if (where.equals("tl")) {
	    dialogClick(new Point(0, 2));
	} else if (where.equals("tr")) {
	    dialogClick(new Point(m_rect.width, 2));
	} else {
	    throw new RuntimeException("Bad refresh arg: " + where);
	}
	flushTextReader();
    }

    public String readText() { return textReader().readText(); }
    public TextReader textReader() {
	if (m_textReader == null) {
	    Rectangle r = textRectangle();
	    m_textReader = new TextReader(r);
	}
	return m_textReader;
    }

    public void flushTextReader() { m_textReader = null; }

    public String textColor(String s) {
	InkSpots[] glyphs = findMatchingLine(s);
	if(glyphs == null) {
	    return null;
	} else {
	    return glyphs[0].color();
	}
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
	    refresh("tl");
	    if(readText().indexOf(text) != -1) {
		return true;
	    }
	    sleepSec(0.1);
	    if(maxSeconds < (System.currentTimeMillis() - start) * 1000) {
		return false;
	    }
	}
    }

    public InkSpots[] findMatchingLine(String start) {
	TextReader tr = textReader();
	for(int i = 0; i < tr.lineText.length; i++) {
	    if(tr.lineText[i].startsWith(start)) {
		return tr.glyphs[i];
	    }
	}
	return null;
    }

    public Point coordsFor(String menu) {
	InkSpots[] glyphs = findMatchingLine(menu);
	if(glyphs == null) {
	    return null;
	}
	InkSpots glyph = glyphs[0];
	int x = glyph.origin[0] + glyph.width / 2;
	int y = glyph.origin[1] + glyph.height / 2;
	return new Point(x, y);
    }

    public static void dismissAll() {
	final ARobot robot = new ARobot();
	// A more or less random point that should be on everyone's screen.
	final Point p = new Point(230, 600);
	// Now, search left/up until we find a non-black pixel
	while(robot.getPixel(p) == 0) {
	    p.x -= 1;
	    p.y -= 1;
	    if (p.x == 0 || p.y == 0) {
		throw new RuntimeException("Didn't find a non-block pixel");
	    }
	}
	robot.withRobotLock(new Runnable() {
		public void run() {
		    // Force a delay.  We're probably here because things are laggy.
		    robot.mm(p, 0.1);
		    robot.sendVk(KeyEvent.VK_ESCAPE);
		    // Now, look to see if the pixel turned black.
		    // This happens when there wasn't anything to dismiss, so the
		    // self menu appeared.  If so, dismiss that.
		    robot.mm(p, 0.1);
		    if (robot.getPixel(p) == 0) {
			robot.sendVk(KeyEvent.VK_ESCAPE);
		    }
		}
	    });
    }

    /**
     * Click on the first line that matches.
     * Returns the last window manipulated on success, nil on failure
     */
    public AWindow clickOn(String menuPath) {
	boolean windowPopped = false;
	AWindow w = this;
	String[] path = menuPath.split("/");
	claimRobotLock();
	try {
	    for(int i = 0; i < path.length; i++) {
		String menu = path[i];
		Point pt = w.coordsFor(menu);
		if (pt == null) {
		    w = null;
		    break;
		}
		if (i >= path.length - 1) { 
		    rclickAt(pt);
		    if (path.length == 1) { w.reconfirmHeight(); }
		}
		else {
		    w = PinnableWindow.fromScreenClick(pt);
		    // Move the mouse out of the way. 
		    if (pt.x > w.getRect().x) {
			mm(w.getRect().x, w.getRect().y);
			sleepSec(0.1);
		    }
		}
		windowPopped = true;
	    }
	    // Is there a dangling window up still?
	    // That happens when we've popped a submenu, but then didn't find
	    // the thing to click on there.
	    if(w == null && windowPopped) { AWindow.dismissAll(); }

	} finally {releaseRobotLock();}
	return w;
    }
}
