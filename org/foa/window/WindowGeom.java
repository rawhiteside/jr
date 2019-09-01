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
	return rectFromPoint(p, true);
    }

    public static Rectangle rectFromPoint(Point p, boolean debug) {
		PixelBlock pb = ARobot.sharedInstance().fullScreenCapture();
		int x = findLeftEdge(pb, p.x, p.y);
		if (x < 0) {
			if(debug) { System.out.println("Failed to find left edge"); }
			return null;
		}

		return rectFromLeftEdge(pb, x, p.y, debug);
    }

    
    // From a point on the left edge. 
    private static Point findOrigin(PixelBlock pb, Point pt) {
		int x = pt.x;
		int y = pt.y;
		//
		// The edge itself is black.  To the right are two pixels of
		// brownish, then another black.  To the right of *that* is
		// the window itself, which is non-black.  We'll search
		// upwards to find the next black pixel, which is the inner
		// border at the top.
		x += 4;
		// Search up for the corner.
		while(pb.pixelFromScreen(x, y) != 0) {
			y -= 1;
			if (y < 0) { return null; }
		}
		// Skip the little gap.
		y -= 3;
		x -=4;
		return new Point(x, y);
    }

    /**
     * Find and return teh width of the window, given the window origin.
     */
    private static int findWidth(PixelBlock pb, Point pt) {
	int screenWidth = ARobot.sharedInstance().screenSize().width;
	int xOrig = pt.x;
	int y = pt.y;
	int x = xOrig;
	// Skip across the border into the interior.  Search
	// rightwards until we find black.  That's the interior of the
	// right border.
	x += 4;
	y += 4;
	while(pb.pixelFromScreen(x, y) != 0) {
	    x += 1;
	    if (x >= screenWidth) { return 0; }
	}
	x += 3;
	return x - xOrig;
    }

    /**
     * Find the height, given the origin of the window.
     */
    private static int findHeight(PixelBlock pb, int x, int y) {
	int yStart = y;

	// Search along the window proper for the black border pixel at the bottom.
	y += 4;
	x += 4;
	while (pb.pixelFromScreen(x, y) != 0) { y += 1; }
	// Skip past bottom border
	y += 3;
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
     * Find the left edge. 
     */
    private static int findLeftEdge(PixelBlock pb, int x, int y) {

		while (x >= 0 && !isLeftEdgeBorder(pb, x, y)) {
			// If we encounter a *right* border, the there was no
			// window there, and we've bumped into another.
			if (isRightEdgeBorder(pb, x, y)) {return -1;}
			x -= 1;
		}
		return x;
    }
    
    public static int INNER_BROWN = new Color(148, 108, 70).getRGB() & 0xFFFFFF;
    public static int OUTER_BROWN = new Color(114, 80, 46).getRGB() & 0xFFFFFF;



    private static boolean isLeftEdgeBorder(PixelBlock pb, int x, int y) {
		int pixel = pb.pixelFromScreen(x, y);
		if (pixel != 0) {
			return false;
		}
		return pb.pixelFromScreen(x+1, y) == OUTER_BROWN;
    }

    private static boolean isRightEdgeBorder(PixelBlock pb, int x, int y) {
		int pixel = pb.pixelFromScreen(x, y);
		if (pixel != 0) {
			return false;
		}
		return pb.pixelFromScreen(x+1, y) == INNER_BROWN;
    }
    
}
