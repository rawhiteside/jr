package org.foa.window;

import org.foa.robot.ARobot;
import org.foa.PixelBlock;

import java.awt.*;

public class PinnableWindowGeom extends ARobot {

	public static Rectangle rectFromPoint(Point p) {
		return rectFromPoint(p, false);
	}

	public static Rectangle rectFromPoint(Point p, boolean debug) {
		System.out.println("rect from point");
		if (isOffScreen(p)) { return null; }
		PixelBlock pb = ARobot.sharedInstance().fullScreenCapture();
		int x = findLeftEdge(pb, p.x, p.y);
		System.out.println("Left edge at " + x);
		if (x < 0) {
			if(debug) { System.out.println("Failed to find left edge"); }
			return null;
		}
	
		Rectangle rv = rectFromLeftEdge(pb, x, p.y, debug);
		if (rv == null) {
			return null;
		}
		return new Rectangle(rv.x, rv.y, rv.width, rv.height);
	}


	// From a point on the left edge.   This point should be a border pixel.
	// Search up until we find a non-border, of the edge of the screen.
	private static Point findOrigin(PixelBlock pb, Point pt) {
		System.out.println("Find orign");
		int x = pt.x;
		int y = pt.y;
		while(isBorder(pb, x, y)) {
			if (y == 0) {
				return new Point(x, y);
			}
			y = y - 1;
		}
		return new Point(x, y + 1);
	}

	/**
	 * Find and return the width of the window, given the window origin.
	 */
	private static int findWidth(PixelBlock pb, Point pt) {
		System.out.println("find widt");
		int screenWidth = ARobot.sharedInstance().screenSize().width;
		int xStart = pt.x;

		// Origin is a border pixel.  Search right for another
		// non-border, or the screen edge.
		int y = pt.y;
		int x = pt.x;
		if (x >= screenWidth) { return 0; }
		while(isBorder(pb, x, y)) {
			x += 1;
			if (x == screenWidth) { break; }
		}
		return x - xStart + 1;
	}

	/**
	 * Find the height, given the origin of the window.
	 */
	private static int findHeight(PixelBlock pb, int x, int y) {
		System.out.println("find height");
		int screenHeight = ARobot.sharedInstance().screenSize().height;
		int yStart = y;

		if (y >= screenHeight) { return 0; }
		// Search down for a non-border, or for the screen edge.
		while(isBorder(pb, x, y)) {
			y += 1;
			if (y == screenHeight) { break; }
		}
		return y - yStart + 1;
	}


	private static Rectangle rectFromLeftEdge(PixelBlock pb, int x, int y, boolean debug) {
		Point origin = findOrigin(pb, new Point(x, y));
		System.out.println("Origin at " + origin);
		int width = findWidth(pb, origin);
		System.out.println("WIdth "+ width);

		int height = findHeight(pb, origin.x, origin.y);
		System.out.println("Height " + height);

		if (height <= 30 || width <= 50) {
			if(debug) { System.out.println("LegacyWindowGeom: Rectangle was too small: " + width + ", " + height); }
			return null;
		}

		return new Rectangle(origin.x, origin.y, width, height);
	}

	/**
	 * Find the left edge. The pixel is a border.  Not background.
	 */
	private static int findLeftEdge(PixelBlock pb, int x, int y) {
		while (x >= 0) {
			if (isBorder(pb, x, y)) { return x; }
			x -= 1;
		}
		return x;
	}

	private static boolean isBorder(PixelBlock pb, int x, int y) {
		Color color = pb.getColorFromScreen(x, y);
		return color.getRed() >= 132 && color.getRed() <= 135 &&
			color.getGreen() >= 101 && color.getGreen() <= 103 &&
			color.getBlue() >= 73 && color.getBlue() <= 76;
			
	}
}
