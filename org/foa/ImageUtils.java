package org.foa;

import java.awt.Color;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.image.*;
import java.util.*;

import org.foa.PixelBlock;

public class ImageUtils {

    public static HashMap[] globify(PixelBlock m, int threshold) {
	return globify(m.bufferedImage(), threshold);
    }

    /**
     * The scheme is this.  Each point gets put into a "glob" as a key
     * a hash.  
     *
     * Adding a point to a glob: When we put one in, we put that point
     * into the hash with a value of "1".  Then, we put all 8
     * neighbors in with a value of "0".  (Unless that neighbor point
     * is already there with a "1" value.)  This "neighbor" stuff is
     * so we know that a point is adnacent to another.
     *
     * To find which glob the next point belongs to, look into each of
     * the existing globs, to see if that point is already there.
     * Here are the possibilities:
     *
     * - Note: Point is NOT in any existing glob with value 1. Each
     * point only gets added once.
     *
     * - Point is exactly one existing as a neighbor (value = 0): 
     * Put the new point into that glob as outlined above.
     *
     * - Point is in multiple globs:  Put the point into one of the
     * globs, and merge all of the other matching ones together.
     *
     * - Point is in no existing glob.  Create a new, empty glob, and
     * add the point as outlined above.
     *
     * At the end, remove all the stoff about neighbors. It was only
     * there for locating the contiguous regions.
     *
     */
    public static HashMap[] globify(BufferedImage bi, int threshold) {
	ArrayList<HashMap> globs = new ArrayList<HashMap>();

	// Do something with each point that is a "hit" (non-zero pixel value).
	for(int y = 0; y < bi.getHeight() - 1; y++) {
	    for(int x = 0; x < bi.getWidth() - 1; x++)  {
		Point p = new Point(x, y);
		// is it a hit or a miss?
		if ((bi.getRGB(x, y) & 0xFFFFFF) > threshold) { globifyPoint(globs, p); }
	    }
	    if ((y % 10) == 9) { pruneGlobs(globs, y, 15); }
	}
	// Now, remove all of the keys with value = 0.
	for(HashMap glob : globs) { removeNeighborsFromGlob(glob); }
	return globs.toArray(new HashMap[globs.size()]);
    }

    // Remove small globs that cannot get larger.

    private static void pruneGlobs(ArrayList<HashMap> globs, int y, int minSize) {
	// Max Y value in a glob.
	int[] maxY = new int[globs.size()];
	HashMap[] maps = new HashMap[globs.size()];
	for(int i = 0; i < globs.size(); i++) {
	    maps[i] = globs.get(i);
	    maxY[i] = 0;
	    Object[] arr = maps[i].keySet().toArray();
	    for(int j = 0; j < arr.length; i++) {
		Point p = (Point)arr[j];
		if(p.y > maxY[i]) {maxY[i] = p.y;}
	    }
	}

	// Now, delete the small globs that can't get bigger.
	for(int i = 0; i < maxY.length; i++) {
	    if (maps[i].size() <= minSize && maxY[i] < (y-1)) {
		globs.remove(maps[i]);
	    }
	}
    }

    public static Point[][] globifyPoints(Point[] points) {
	ArrayList<HashMap> globs = new ArrayList<HashMap>();
	for(int i = 0; i < points.length; i++) { globifyPoint(globs, points[i]); }
	
	// Now, remove all of the keys with value = 0.
	for(HashMap glob : globs) { removeNeighborsFromGlob(glob); }
	return globsAsArrays(globs);
    }

    private static Point[][] globsAsArrays(ArrayList<HashMap> globs) {
	Point[][] rv = new Point[globs.size()][];
	for(int i = 0; i < globs.size(); i++) {
	    Object[] tmp = globs.get(i).keySet().toArray();
	    Point ptmp[] = new Point[tmp.length];
	    for(int j = 0; j < tmp.length; j++) {
		ptmp[j] = (Point) tmp[j];
	    }
	    rv[i] = ptmp;
	}
	return rv;
    }

    private static void globifyPoint(ArrayList<HashMap> globs, Point p) {
	// The list of globs we can add this point to. 
	ArrayList<HashMap> addedTo = new ArrayList<HashMap>();

	// Which globs can we add this point to? 
	for(HashMap glob : globs) {
	    if(maybeAdd(glob, p)) { addedTo.add(glob); }
	}

	// How many did we add the point to?
	if(addedTo.size() == 0) {
	    // None.  Create a new glob
	    HashMap glob = new HashMap();
	    addPointToGlob(p, glob);
	    globs.add(glob);
	} else if (addedTo.size() > 1) {
	    // Multiple globs.  We must merge them.
	    HashMap keep = addedTo.get(0);
	    ArrayList<HashMap> removals = new ArrayList<HashMap>();
	    for(int i = 1; i < addedTo.size(); i++) {
		mergeGlobs(keep, addedTo.get(i));
		removals.add(addedTo.get(i));
	    }
	    for(HashMap hm : removals) { globs.remove(hm); }
	}
    }

    private static void removeNeighborsFromGlob(HashMap glob) {
	ArrayList removeThese = new ArrayList();
	Iterator itr = glob.keySet().iterator();
	while(itr.hasNext()) {
	    Point p = (Point) itr.next();
	    if (glob.get(p).equals(NEIGH_VAL)) {
		removeThese.add(p);
	    }
	}
	itr = removeThese.iterator();
	while (itr.hasNext()) {
	    Point p = (Point) itr.next();
	    glob.remove(p);
	}
    }

    private static Integer POINT_VAL = new Integer(1);
    private static Integer NEIGH_VAL = new Integer(0);
    
    private static void addPointToGlob(Point p, HashMap glob) {
	putPoint(glob, p, POINT_VAL);
	putPoint(glob, new Point(p.x + 1, p.y + 1), NEIGH_VAL);
	putPoint(glob, new Point(p.x + 1, p.y + 0), NEIGH_VAL);
	putPoint(glob, new Point(p.x + 1, p.y - 1), NEIGH_VAL);

	putPoint(glob, new Point(p.x + 0, p.y + 1), NEIGH_VAL);
	putPoint(glob, new Point(p.x + 0, p.y - 1), NEIGH_VAL);

	putPoint(glob, new Point(p.x - 1, p.y + 1), NEIGH_VAL);
	putPoint(glob, new Point(p.x - 1, p.y + 0), NEIGH_VAL);
	putPoint(glob, new Point(p.x - 1, p.y - 1), NEIGH_VAL);
    }

    private static void putPoint(HashMap glob, Point p, Integer val) {
	// Values of nil, 0, or 1. 0 is "neighbor", 1 is "point".
	// A "neighbor" won't overwrite a "point"
	Integer current = (Integer) glob.get(p);
	if ((current == null) || (current < val)) { glob.put(p, val); }
    }

    private static void mergeGlobs(HashMap dest, HashMap source) {
	Iterator itr = source.keySet().iterator();
	while(itr.hasNext()) {
	    Point p = (Point) itr.next();
	    putPoint(dest, p, (Integer) source.get(p));
	}
    }

    private static boolean maybeAdd(HashMap glob, Point p) {
	Integer current = (Integer) glob.get(p);
	if (current == null) {
	    return false;
	} else {
	    addPointToGlob(p, glob);
	    return true;
	}
	
    }

    public static BufferedImage imageFromPoints(BufferedImage bi, Point[] points)  {
	BufferedImage biOut =
            new BufferedImage(bi.getWidth(), bi.getHeight(), BufferedImage.TYPE_INT_RGB);
	WritableRaster raster = biOut.getRaster();
	int[] zeros = {0, 0, 0};
	int[] ones = {255, 255, 255};
        for(int x = 1; x < bi.getWidth()-1; x++) {
            for(int y = 1; y < bi.getHeight()-1; y++) {
		raster.setPixel(x, y, zeros);
	    }
	}
	for(int i = 0; i < points.length; i++) {
	    Point p = points[i];
	    raster.setPixel(p.x, p.y, ones);
	}
	return biOut;
    }
    /**
     * Return an image constructed from the xor of the two input images.
     */
    public static BufferedImage xor(BufferedImage bi1, BufferedImage bi2) {
        BufferedImage biOut =
            new BufferedImage(bi1.getWidth(), bi1.getHeight(), BufferedImage.TYPE_INT_RGB);
        for(int x = 0; x < bi1.getWidth(); x++) {
            for(int y = 0; y < bi1.getHeight(); y++) {
		int pixel = bi1.getRGB(x, y) ^ bi2.getRGB(x, y);
		biOut.setRGB(x, y, pixel);
	    }
	}
	return biOut;
    }

    public static PixelBlock xor(PixelBlock pb1, PixelBlock pb2) {
	return new PixelBlock(pb1.origin(),
			      xor(pb1.bufferedImage(), pb2.bufferedImage()));
    }


    /**
     * Find the pixel that's largest.  I can start its search
     * at the top, bottom, right, or left.  specify one of those
     * strings, as in, "top"
     *
     * The image should probably be a brightness image.
     *
     * Search stops when it his the excluded radius, which is at the
     * center of the block.
     *
     * returns a Point.
     */
    public static Point findLargest(PixelBlock pb, String which, int excluded) {
	return findLargest(pb.bufferedImage(), which, excluded);
    }

    public static Point findLargest(BufferedImage bi, String which, int excluded) {
	int xfirst=0, xend=0, xoff=0;
	int yfirst=0, yend=0, yoff=0;
	boolean xouter = false;

	switch(which) {
	case "top":
	    xouter = false;
	    yfirst = 2;
	    yend = bi.getHeight()/2 - excluded;
	    yoff = 1;
	    break;
	case "bottom":
	    xouter = false;
	    yfirst = bi.getHeight() - 2;
	    yend = bi.getHeight()/2 + excluded;
	    yoff = -1;
	    break;
	case "left":
	    xouter = true;
	    xfirst = 0;
	    xend = bi.getWidth()/2 - excluded;
	    xoff = 1;
	    break;
	case "right":
	    xouter = true;
	    xfirst = bi.getWidth() - 1;
	    xend = bi.getWidth()/2 + excluded;
	    xoff = -1;
	    break;
	default:
	    return null;
	}
	int bestColor = 0;
	Point bestPoint = null;
	if(xouter) {
	    for(int x = xfirst; x != xend; x += xoff) {
		for(int y = 0; y < bi.getHeight(); y++) {
		    int color = bi.getRGB(x, y) & 0xFFFFFF;
		    if(color  > bestColor) {
			bestColor = color;
			bestPoint = new Point(x, y);
		    }
		}
	    }
	} else {
	    for(int y = yfirst; y != yend; y += yoff) {
		for(int x = 0; x < bi.getWidth(); x++) {
		    int color = bi.getRGB(x, y) & 0xFFFFFF;
		    if(color  > bestColor) {
			bestColor = color;
			bestPoint = new Point(x, y);
		    }
		}
	    }
	}
	return bestPoint;
    }
    
    
    /**
     * Replace each pixel with its brightness
     */
    public static PixelBlock brightness(PixelBlock pb) {
	return new PixelBlock(pb.origin(), brightness(pb.bufferedImage()));
    }

    public static BufferedImage brightness(BufferedImage bi) {
        BufferedImage biOut =
            new BufferedImage(bi.getWidth(), bi.getHeight(), BufferedImage.TYPE_INT_RGB);
        for(int x = 0; x < bi.getWidth(); x++) {
            for(int y = 0; y < bi.getHeight(); y++) {
		Color color = new Color(bi.getRGB(x, y));
		int pixel = (color.getRed() + color.getGreen() + color.getBlue()) / 3;
		biOut.setRGB(x, y, pixel);
	    }
	}
	return biOut;
    }

    /**
     * Computes an output image that has removed every pixel that has
     * a zero-value neighbor pixel. Looks at all eight.
     *
     * Just uses pixel valies directly, and looks for zero, where zero
     * is defined by threshold.  Pass this a brightness image.
     */
    public static PixelBlock shrink(PixelBlock pb, int threshold) {
	return new PixelBlock(pb.origin(), shrink(pb.bufferedImage(), threshold, 0));
    }
    public static PixelBlock shrink(PixelBlock pb, int threshold, int count) {
	return new PixelBlock(pb.origin(), shrink(pb.bufferedImage(), threshold, count));
    }
    public static BufferedImage shrink(BufferedImage bi, int threshold) {
	return shrink(bi, threshold, 0);
    }

    public static BufferedImage shrink(BufferedImage bi, int threshold, int count) {
        BufferedImage biOut =
            new BufferedImage(bi.getWidth(), bi.getHeight(), BufferedImage.TYPE_INT_RGB);
	WritableRaster raster = biOut.getRaster();
	int[] zeros = {0, 0, 0};

	// First and last output columns are zero.
	for(int y = 0; y < bi.getHeight(); y++) {
	    raster.setPixel(0, y, zeros);
	    raster.setPixel(bi.getWidth()-1, y, zeros);
	}
	// First and last output rows are zero.
	for(int x = 0; x < bi.getWidth(); x++) {
	    raster.setPixel(x, 0, zeros);
	    raster.setPixel(x, bi.getHeight() - 1, zeros);
	}

	boolean flag = false;
        for(int x = 1; x < bi.getWidth()-1; x++) {
            for(int y = 1; y < bi.getHeight()-1; y++) {
		int n = countZeroNeighbors(bi, x, y, threshold);
		if (n <= count) {
		    Color c = new Color(bi.getRGB(x, y));
		    int[] cvec = {c.getRed(), c.getGreen(), c.getBlue()};
		    raster.setPixel(x, y, cvec); 
		}
		else {
		    raster.setPixel(x, y, zeros);
		}
	    }
	}
	return biOut;
    }

    private static int countZeroNeighbors(BufferedImage bi, int x, int y, int threshold) {
	int count = 0;
	if ((bi.getRGB(x-1, y-1) & 0xFFFFFF) < threshold) {count++;}
	if ((bi.getRGB(x-0, y-1) & 0xFFFFFF) < threshold) {count++;}
	if ((bi.getRGB(x+1, y-1) & 0xFFFFFF) < threshold) {count++;}
	if ((bi.getRGB(x-1, y-0) & 0xFFFFFF) < threshold) {count++;}
	if ((bi.getRGB(x-0, y-0) & 0xFFFFFF) < threshold) {count++;}
	if ((bi.getRGB(x+1, y-0) & 0xFFFFFF) < threshold) {count++;}
	if ((bi.getRGB(x-1, y+1) & 0xFFFFFF) < threshold) {count++;}
	if ((bi.getRGB(x-0, y+1) & 0xFFFFFF) < threshold) {count++;}
	if ((bi.getRGB(x+1, y+1) & 0xFFFFFF) < threshold) {count++;}
	return count;
    }

    /**
     * Output image finds every zero pixel in the input that has a
     * non-zero pixel as a neighbor and turns it into a one.
     */
    public static PixelBlock expand(PixelBlock pb) {
	return new PixelBlock(pb.origin(), expand(pb.bufferedImage()));
    }
    public static BufferedImage expand(BufferedImage bi) {
        BufferedImage biOut =
            new BufferedImage(bi.getWidth(), bi.getHeight(), BufferedImage.TYPE_INT_RGB);
	WritableRaster raster = biOut.getRaster();
	int[] zeros = {0, 0, 0};
	int[] ones = {255, 255, 255};

	// First and last output columns are zero.
	for(int y = 0; y < bi.getHeight(); y++) {
	    raster.setPixel(0, y, zeros);
	    raster.setPixel(bi.getWidth()-1, y, zeros);
	}
	// First and last output rows are zero.
	for(int x = 0; x < bi.getWidth(); x++) {
	    raster.setPixel(x, 0, zeros);
	    raster.setPixel(x, bi.getHeight() - 1, zeros);
	}

        for(int x = 1; x < bi.getWidth()-1; x++) {
            for(int y = 1; y < bi.getHeight()-1; y++) {
		if ((bi.getRGB(x-1, y-1) & 0xFFFFFF)  == 0 &&
		    (bi.getRGB(x-0, y-1) & 0xFFFFFF) == 0 &&
		    (bi.getRGB(x+1, y-1) & 0xFFFFFF) == 0 &&
		    (bi.getRGB(x-1, y-0) & 0xFFFFFF) == 0 &&
		    (bi.getRGB(x-0, y-0) & 0xFFFFFF) == 0 &&
		    (bi.getRGB(x+1, y-0) & 0xFFFFFF) == 0 &&
		    (bi.getRGB(x-1, y+1) & 0xFFFFFF) == 0 &&
		    (bi.getRGB(x-0, y+1) & 0xFFFFFF) == 0 &&
		    (bi.getRGB(x+1, y+1) & 0xFFFFFF) == 0) {

		    raster.setPixel(x, y, zeros);
		}
		else {
		    raster.setPixel(x, y, ones); 
		}
	    }
	}
	return biOut;
    }

    /**
     * Find edges.
     */
    public static PixelBlock edges(PixelBlock pb) {
	return new PixelBlock(pb.origin(), edges(pb.bufferedImage()));
    }
    public static BufferedImage edges(BufferedImage bi) {
        BufferedImage biOut =
            new BufferedImage(bi.getWidth(), bi.getHeight(), BufferedImage.TYPE_INT_RGB);

	float[] elements = {0.0f, -1.0f, 0.0f,
			    -1.0f, 4.f, -1.0f,
			    0.0f, -1.0f, 0.0f};
	Kernel kernel = new Kernel(3, 3, elements);
	ConvolveOp cop = new ConvolveOp(kernel, ConvolveOp.EDGE_NO_OP, null);
	cop.filter(bi,biOut);

	return biOut;
    }

    /**
     * Blur the image
     */
    public static PixelBlock blur(PixelBlock pb) {
	return new PixelBlock(pb.origin(), blur(pb.bufferedImage()));
    }
    public static BufferedImage blur(BufferedImage bi) {
        BufferedImage biOut =
            new BufferedImage(bi.getWidth(), bi.getHeight(), BufferedImage.TYPE_INT_RGB);

	float weight = 1.0f/9.0f;
	float[] elements = new float[9];
	for(int i = 0; i < 9; i++) {
	    elements[i] = weight;
	}

	Kernel kernel = new Kernel(3, 3, elements);
	ConvolveOp cop = new ConvolveOp(kernel, ConvolveOp.EDGE_NO_OP, null);
	cop.filter(bi,biOut);

	return biOut;
    }
}
