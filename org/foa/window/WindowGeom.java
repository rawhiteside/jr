package org.foa.window;

import org.foa.robot.ARobot;
import org.foa.PixelBlock;

import java.awt.*;

public class WindowGeom extends ARobot {

	public static void waitForChatMinimized() {
		ARobot robot = ARobot.sharedInstance();
		Dimension screen = robot.screenSize();
		int x = screen.width - 2;
		int y = screen.height - 34;
		Point p = new Point(x, y);
		while(true) {
			Color c = robot.getColor(p);
			if ((c.getRed() + c.getGreen() + c.getBlue()) < 250) { return; }
			robot.sleepSec(0.5);
		}
	
	}

	public static Rectangle rectFromPoint(Point p) {
		return rectFromPoint(p, false);
	}

	public static Rectangle rectFromPoint(Point p, boolean debug) {
		PixelBlock pb = ARobot.sharedInstance().fullScreenCapture();
		int x = findLeftEdge(pb, p.x, p.y);
		if (x < 0) {
			if(debug) { System.out.println("Failed to find left edge"); }
			return null;
		}
	
		Rectangle rv = rectFromLeftEdge(pb, x, p.y, debug);
		if (rv == null) {
			return null;
		}
		// Need to fix, but this returns the rectangle inner border.
		// We're expected to return the whole window, which is 3
		// pixels larger alll 'round.  Fix that.
		return new Rectangle(rv.x - 3, rv.y - 3, rv.width + 6, rv.height + 6);
	}


	// From a point on the left edge.   This point should be a border pixel.
	private static Point findOrigin(PixelBlock pb, Point pt) {
		int x = pt.x;
		int y = pt.y;
		//
		// Move right one pixel, then search up for another border pixel.
		x += 1;
		while(!isInnerBorder(pb, x, y)) {
			y = y - 1;
			if (y < 0) {
				return null;
			}
		}

		return new Point(x-1, y);
	}

	/**
	 * Find and return the width of the window, given the window origin.
	 */
	private static int findWidth(PixelBlock pb, Point pt) {
		int screenWidth = ARobot.sharedInstance().screenSize().width;
		int xStart = pt.x;

		// Origin is a border pixel.  Move in to the window, then
		// search right for another border.
		int y = pt.y + 1;
		int x = pt.x + 1;
		while(!isInnerBorder(pb, x, y)) {
			x += 1;
			if (x >= screenWidth) { return 0; }
		}
		return x - xStart;
	}

	/**
	 * Find the height, given the origin of the window.
	 */
	private static int findHeight(PixelBlock pb, int x, int y) {
		int screenHeight = ARobot.sharedInstance().screenSize().height;
		int yStart = y;

		// Origin is a border pixel.  Move in to the window, then
		// search down for another border.
		y += 1;
		x += 1;

		while(!isInnerBorder(pb, x, y)) {
			y += 1;
			if (y >= screenHeight) { return 0; }
		}
		return y - yStart;
	}


	private static Rectangle rectFromLeftEdge(PixelBlock pb, int x, int y, boolean debug) {
		Point origin = findOrigin(pb, new Point(x, y));
		if (origin == null) {
			if(debug) { System.out.println("Failed to find origin"); }
			return null;
		}
		int width = findWidth(pb, origin);
		int height = findHeight(pb, origin.x, origin.y);

		if (height <= 10 || width <= 10) {
			if(debug) { System.out.println("Rectangle was too small: " + width + ", " + height); }
			return null;
		}

		return new Rectangle(origin.x, origin.y, width, height);
	}

	/**
	 * Find the left edge. The pixel is a border.  Not background.
	 */
	private static int findLeftEdge(PixelBlock pb, int x, int y) {
		while (x >= 0 && !isInnerBorder(pb, x, y)) {
			// If we encounter a *right* border, the there was no
			// window there, and we've bumped into another.
			if (isOuterBorder(pb, x, y)) {
				return -1;
			}

			x -= 1;
		}
		return x;
	}

	public static Color INNER_BROWN = new Color(107, 69, 41);
	public static Color OUTER_BROWN = new Color(163, 116, 64);



	private static boolean isInnerBorder(PixelBlock pb, int x, int y) {
		Color color = pb.colorFromScreen(x, y);
		return Math.abs(color.getRed() - INNER_BROWN.getRed()) <= 4 &&
			Math.abs(color.getGreen() - INNER_BROWN.getGreen()) <= 4 &&
			Math.abs(color.getBlue() - INNER_BROWN.getBlue()) <= 4;
	}

	private static boolean isOuterBorder(PixelBlock pb, int x, int y) {
		return isOuterBorder(pb.color(x, y));
	}
	
	public static boolean isOuterBorder(Color color) {
		return Math.abs(color.getRed() - OUTER_BROWN.getRed()) <= 10 &&
			Math.abs(color.getGreen() - OUTER_BROWN.getGreen()) <= 12 &&
			Math.abs(color.getBlue() - OUTER_BROWN.getBlue()) <= 6;
	}

}
