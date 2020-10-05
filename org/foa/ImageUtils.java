package org.foa;

import java.awt.Color;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.Graphics2D;
import java.awt.image.*;

import java.util.*;

import org.foa.PixelBlock;

public class ImageUtils {

	/**
	 * Search image for an exact subimage match for template. Return
	 * the furst found. Null if not found.
	 */
	public static Point findTemplateExact(BufferedImage image, BufferedImage template) {
		for(int y = 0; y < (image.getHeight() - template.getHeight()); y++) {
			for(int x = 0; x < (image.getWidth() - template.getWidth()); x++) {
				if (templateMatchesHere(image, template, x, y))
					return new Point(x, y);
			}
		}
		return null;
	}


	private static boolean templateMatchesHere(BufferedImage image, BufferedImage template, int x, int y) {
		int height = template.getHeight();
		int width =  template.getWidth();
		for(int iy = 0; iy < height; iy++) {
			for(int ix = 0; ix < width; ix++) {

				int cTemplate = template.getRGB(ix, iy) & 0xFFFFFF;

				int cImage = image.getRGB(x + ix, y + iy) & 0xFFFFFF;
				if(cImage != cTemplate) {
					return false;
				}
			}
		}
		return true;
	}

	public static BufferedImage resize(BufferedImage inputImage, float factor) {
 
		int outputWidth = (int) (inputImage.getWidth() / factor);
		int outputHeight = (int) (inputImage.getHeight() / factor);

        // creates output image
        BufferedImage outputImage = new BufferedImage(outputWidth, outputHeight, inputImage.getType());
 
        // scales the input image to the output image
        Graphics2D g2d = outputImage.createGraphics();
        g2d.drawImage(inputImage, 0, 0, outputWidth, outputHeight, null);
        g2d.dispose();
 
		return outputImage;
    }
 

	/**
	 * Put white spots into the image at the provided points, with a black background. 
	 */
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

	/**
	 * XOR the two pixelblocks. 
	 */
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
