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
	int x = findLeftEdge(p.x, p.y);
	if (x < 0) {
	    return null;
	}
	return rectFromLeftEdge(x, p.y);
    }

    // Wait a while for the edge to appear, if it has not yet.
    private static void waitForEdge(Rectangle r) {
	for(int i = 0; i < 10; i++) {
	    PixelBlock pb = new PixelBlock(r);
	    Boolean allBlack = true;
	    for(int yoff = 0; yoff > -10; yoff--) {
		if (pb.pixelFromScreen(r.x, r.y + yoff) != 0) {
		    allBlack = false;
		    break;
		}
	    }
	    if (allBlack) { break; }
	    ARobot.sharedInstance().sleepSec(0.01);
	}
    }

    
    // From a point on the left edge. 
    private static Point findOrigin(Point pt) {
	int x = pt.x;
	int y = pt.y;
	Rectangle edgeRect = new Rectangle(x, 0, 1, y+1);
	waitForEdge(edgeRect);
	//
	// The edge itself is black.  To the right are two pixels of
	// brownish, then another black.  To the right of *that* is
	// the window itself, which is non-black.  We'll search
	// upwards to find the next black pixel, which is the inner
	// border at the top.
	edgeRect.x += 4;
	x += 4;
	PixelBlock pb = new PixelBlock(edgeRect);
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
    private static int findWidth(Point pt) {
	int screenWidth = ARobot.sharedInstance().screenSize().width;
	int xOrig = pt.x;
	int y = pt.y;
	int x = xOrig;
	// Skip across the border into the interior.  Search
	// rightwards until we find black.  That's the interior of the
	// right border.
	x += 4;
	y += 4;
	PixelBlock pb = new PixelBlock(new Rectangle(x, y, screenWidth - x, 1));
	while(pb.pixelFromScreen(x, y) != 0) {
	    x += 1;
	    if (x >= screenWidth) { break; }
	}
	x += 3;
	return x - xOrig;
    }

    // Make sure the height hasn't changed since the last time we
    // looked at the window.  If it has, then recompute it by looking
    // at the vertical line through the center of the window.
    public static Rectangle confirmHeight(Rectangle rect) {
	ARobot robot = ARobot.sharedInstance();
	for(int i = 0; i < 5; i++) {
	    Rectangle r = tryConfirmHeight(rect);
	    // If the rectangle seems bad, wait and try again. 
	    if (r.height < 40 || r.height > 600) {
		robot.sleepSec(0.1);
	    } else {
		return r;
	    }
	}
	return rect;
    }


    private static Rectangle tryConfirmHeight(Rectangle rectIn) {
	Rectangle rect = new Rectangle(rectIn);
	int x = rect.x + rect.width/2;
	int y = rect.y;
	ARobot robot = ARobot.sharedInstance();
	int screenHeight = robot.screenSize().height;
	PixelBlock pb = new PixelBlock(new Rectangle(x, 0, 1, robot.screenSize().height));
	if (pb.pixelFromScreen(x, y) == 0 &&
	    pb.pixelFromScreen(x, y + 3) == 0 &&
	    pb.pixelFromScreen(x, y + rect.height) == 0 &&
	    pb.pixelFromScreen(x, y + rect.height - 3) == 0) {

	    // Looks OK.  No change necessary
	    return rect;
	}
	// Start searching upwards frum the center, looking for the border.
	int ymin = -1;
	for (int iy = y + rect.height/2; iy > 3; iy--){
	    if (pb.pixelFromScreen(x, iy) != 0 ||
		pb.pixelFromScreen(x, iy - 3) != 0 ) continue;
	    if (INNER_BROWN != pb.pixelFromScreen(x, iy - 1) ||
		OUTER_BROWN != pb.pixelFromScreen(x, iy - 2)) continue;
	    ymin = iy - 3;
	    break;
	}
	
	// Now, search down to find the bottom.
	int ymax = -1;
	for (int iy = y + rect.height/2; iy < screenHeight - 3; iy++){
	    if (pb.pixelFromScreen(x, iy) != 0 ||
		pb.pixelFromScreen(x, iy + 3) != 0 ) continue;
	    if (INNER_BROWN != pb.pixelFromScreen(x, iy + 1) ||
		OUTER_BROWN != pb.pixelFromScreen(x, iy + 2)) continue;
	    ymax = iy + 3;
	    break;
	}
	rect.height = ymax - ymin;
	rect.y = ymin;

	return rect;
    }

    /**
     * Find the height, given the origin of the window.
     */
    private static int findHeight(int x, int y) {
	int yStart = y;
	int screenHeight = ARobot.sharedInstance().screenSize().height;
	// Search along the window proper for the black border pixel at the bottom.
	y += 4;
	x += 4;
	PixelBlock pb = new PixelBlock(new Rectangle(x, y, 1, screenHeight - y + 1));
	while (pb.pixelFromScreen(x, y) != 0) { y += 1; }
	// Skip past bottom border
	y += 3;
	return y - yStart;
    }


    private static Rectangle rectFromLeftEdge(int x, int y) {
	Point origin = findOrigin(new Point(x, y));
	if (origin == null) {return null;}
	int width = findWidth(origin);
	int height = findHeight(origin.x, origin.y);
	return new Rectangle(origin.x, origin.y, width, height);
    }
    
    /**
     * Find the left edge. 
     */
    private static int findLeftEdge(int x, int y) {
	int xStart = x;
	PixelBlock pb = new PixelBlock(new Rectangle(0, y, x+2, 1));
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
