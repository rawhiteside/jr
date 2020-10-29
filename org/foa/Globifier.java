package org.foa;

import java.awt.Color;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.Graphics2D;
import java.awt.image.*;

import java.util.*;

import org.foa.PixelBlock;

/**
 * Looks at an image with some zero and non-zero pixels.  Finds the
 * globs of contiguous non-zero pixels.
 *
 * Used, e.g., in mining to find the stones from a before/after xor. 
 */
public class Globifier {
	public static Point[][] globify(PixelBlock m) {
		return globify(m.bufferedImage());
	}

	/**
	 * The scheme is this.  Each point gets put into a "glob" as a key
	 * a hash.  
	 *
	 * Adding a point to a glob: When we put one in, we put that point
	 * into the hash with a value of "1".  Then, we put all 8
	 * neighbors in with a value of "0".  (Unless that neighbor point
	 * is already there with a "1" value.)  This "neighbor" stuff is
	 * so we know that a point is adjacent to another.
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
	 * @returns An array of hashmaps, one for each contiguous glob.
	 * Keys are the points, values just "1".
	 */
	public static Point[][] globify(BufferedImage bi) {
		return globify(bi, 40000, 100);  // 10x a typical ore stone.
	}
	public static Point[][] globify(BufferedImage bi, int maxSize, int minSize) {
		ArrayList<HashMap> globs = new ArrayList<HashMap>();

		// Do something with each point that is a "hit" (non-zero pixel value).
		for(int y = 0; y < bi.getHeight() - 1; y++) {
			for(int x = 0; x < bi.getWidth() - 1; x++)  {
				Point p = new Point(x, y);
				// is it a hit or a miss?
				if ((bi.getRGB(x, y) & 0xFFFFFF) != 0) { globifyPoint(globs, p); }
			}
			if ((y % 10) == 9) { pruneGlobs(globs, y, 100); }
			// If a glob gets too big, something went wrong.
			// (Sometimes the whole screen changes, I think.)
			// Return null.
			for(HashMap glob : globs) {
				if(glob.size() > maxSize) { return new Point[0][]; }
			}
		}
		// Now, remove all of the keys with value = 0.
		for(HashMap glob : globs) { removeNeighborsFromGlob(glob); }

		return globsAsArrays(globs);
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
			for(int j = 0; j < arr.length; j++) {
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
}
