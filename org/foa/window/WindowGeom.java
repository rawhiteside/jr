package org.foa.window;

import org.foa.robot.ARobot;
import org.foa.PixelBlock;

import java.awt.*;

public class WindowGeom extends ARobot {

    public WindowGeom() {
	super();
    }

    public static Rectangle rectFromPoint(Point p) {
	WindowGeom w = new WindowGeom();
	int x = w.findLeftEdge(p.x, p.y);
	if (x < 0) {
	    return null;
	}
	return w.rectFromLeftEdge(x, p.y);
    }

    // Wait a while for the edge to appear, if it has not yet.
    private void waitForEdge(Rectangle r) {
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
	    sleepSec(0.01);
	}
    }

    
    // From a point on the left edge. 
    public Point findOrigin(Point pt) {
	int x = pt.x;
	int y = pt.y;
	Rectangle edgeRect = new Rectangle(x, 0, 1, y+1);
	waitForEdge(edgeRect);
	PixelBlock pb = new PixelBlock(edgeRect);
	// Search up for the corner.
	while(pb.pixelFromScreen(x, y) == 0) {
	    y -= 1;
	}
	// Skip the little gap.
	y -= 2;
	return new Point(x, y);
    }

    /**
     * Find and return teh width of the window, given the window origin.
     */
    public int findWidth(Point pt) {
	int screenWidth = screenSize().width;
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
	    if (x >= screenWidth) {
		break;
	    }
	}
	x += 3;
	return x - xOrig;
    }

    // Make sure the height hasn't changed since the last time we
    // looked at the window.  If it has, then recompute it by looking
    // at the vertical line through the center of the window.
    public void confirmHeight(Rectangle rect) {
	int x = rect.x + rect.width/2;
	int y = rect.y;
	int screenHeight = screenSize().height;
	PixelBlock pb = new PixelBlock(new Rectangle(x, 0, 1, screenSize().height));

	if (pb.pixelFromScreen(x, y) == 0 &&
	    pb.pixelFromScreen(x, y + 3) == 0 &&
	    pb.pixelFromScreen(x, y + rect.height) == 0 &&
	    pb.pixelFromScreen(x, y + rect.height - 3) == 0) {

	    // Looks OK.  No change necessary
	    return;
	}
	// Start searching upwards frum the center, looking for the border.
	int ymin = -1;
	for (int iy = y + rect.height/2; iy > 3; iy--){
	    if (pb.pixelFromScreen(x, iy) != 0 ||
		pb.pixelFromScreen(x, iy - 3) != 0 ) continue;
	    if (!isBorderBrown(pb.pixelFromScreen(x, iy - 1)) ||
		!isBorderBrown(pb.pixelFromScreen(x, iy - 2))) continue;
	    ymin = iy - 3;
	    break;
	}
	
	// Now, search down to find the bottom.
	int ymax = -1;
	for (int iy = y + rect.height/2; iy < screenHeight - 3; iy++){
	    if (pb.pixelFromScreen(x, iy) != 0 ||
		pb.pixelFromScreen(x, iy + 3) != 0 ) continue;
	    if (!isBorderBrown(pb.pixelFromScreen(x, iy + 1)) ||
		!isBorderBrown(pb.pixelFromScreen(x, iy + 2))) continue;
	    ymax = iy + 3;
	    break;
	}
	rect.height = ymax - ymin + 1;
	rect.y = ymin;
    }

    /**
     * Find the height, given the origin of the window.
     */
    public int findHeight(int x, int y) {
	int yStart = y;
	int screenHeight = screenSize().height;
	PixelBlock pb = new PixelBlock(new Rectangle(x, y, 1, screenHeight - y + 1));
	// Skip past the little gap.
	y += 3;
	while (pb.pixelFromScreen(x, y) == 0) {
	    y += 1;
	}
	// Skip past the little gap at the other end.
	y += 2;
	return y - yStart;
    }


    public Rectangle rectFromLeftEdge(int x, int y) {
	Point origin = findOrigin(new Point(x, y));
	int width = findWidth(origin);
	int height = findHeight(origin.x, origin.y);
	return new Rectangle(origin.x, origin.y, width, height);
    }
    
    /**
     * Find the left edge. 
     */
    public int findLeftEdge(int x, int y) {
	int xStart = x;
	PixelBlock pb = new PixelBlock(new Rectangle(0, y, x+2, 1));
	while (x >= 0 && !isLeftEdgeBorder(pb, x, y)) {
	    x -= 1;
	    // XXX Deal with this better.  Don't want to search all across the screen
	    // and pick up some other window.  I need to have a itsNotAWindowPixel() method.
	    if ((xStart - x) > 500) {
		return -1;
	    }
	}
	return x;
    }
    
    private static int BROWN1 = new Color(148, 108, 70).getRGB() & 0xFFFFFF;
    private static int BROWN2 = new Color(114, 80, 46).getRGB() & 0xFFFFFF;
    private boolean isBorderBrown(int pixel) {
	return (pixel == BROWN1 || pixel == BROWN2);
    }

    private boolean isLeftEdgeBorder(PixelBlock pb, int x, int y) {
	int pixel = pb.pixelFromScreen(x, y);
	if (pixel != 0) {
	    return false;
	}
	return isBorderBrown(pb.pixelFromScreen(x+1, y));
    }
    
}
