package org.foa;

import java.awt.Color;
import java.awt.Point;
import java.awt.image.*;

import org.foa.PixelBlock;

public class ImageUtils {
    /**
     * Return an image constructed from the xor of the two input images.
     * TODO:  Just use the DataBuffer for performance
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
     * Find the first pixel that's non-zero.  I can start its search
     * at the top, bottom, right, or left.  specify one of those
     * strings, as in, "top"
     *
     * returns a Point.
     */
    public static Point firstNonZero(PixelBlock pb, String which) {
	return firstNonZero(pb.bufferedImage(), which);
    }

    public static Point firstNonZero(BufferedImage bi, String which) {
	int xfirst=0, xend=0, xoff=0;
	int yfirst=0, yend=0, yoff=0;
	boolean xouter = false;

	switch(which) {
	case "top":
	    xouter = false;
	    yfirst = 0;
	    yend = bi.getHeight();
	    yoff = 1;
	    break;
	case "bottom":
	    xouter = false;
	    yfirst = bi.getHeight() - 1;
	    yend = -1;
	    yoff = -1;
	    break;
	case "left":
	    xouter = true;
	    xfirst = 0;
	    xend = bi.getWidth();
	    xoff = 1;
	    break;
	case "right":
	    xouter = true;
	    xfirst = bi.getWidth() - 1;
	    xend = -1;
	    xoff = -1;
	    break;
	default:
	    System.out.println("Parts of ImageUtils.firstNonZero not implemented");
	    return null;
	}
	if(xouter) {
	    for(int x = xfirst; x != xend; x += xoff) {
		for(int y = 0; y < bi.getHeight(); y++) {
		    if((bi.getRGB(x, y) & 0xFFFFFF) != 0) { return new Point(x, y); }
		}
	    }
	    return null;
	} else {
	    for(int y = yfirst; y != yend; y += yoff) {
		for(int x = 0; x < bi.getWidth(); x++) {
		    if((bi.getRGB(x, y) & 0xFFFFFF) != 0) { return new Point(x, y); }
		}
	    }
	    return null;
	}
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
     * Just uses pixel valies directly, and looks for zero.  
     */
    public static PixelBlock insides(PixelBlock pb) {
	return new PixelBlock(pb.origin(), insides(pb.bufferedImage()));
    }
    public static BufferedImage insides(BufferedImage bi) {
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

	boolean flag = false;
        for(int x = 1; x < bi.getWidth()-1; x++) {
            for(int y = 1; y < bi.getHeight()-1; y++) {
		if (flag) {
		    raster.setPixel(x, y, ones);
		} else {
		    if ((bi.getRGB(x-1, y-1) & 0xFFFFFF)  != 0 &&
			(bi.getRGB(x-0, y-1) & 0xFFFFFF) != 0 &&
			(bi.getRGB(x+1, y-1) & 0xFFFFFF) != 0 &&
			(bi.getRGB(x-1, y-0) & 0xFFFFFF) != 0 &&
			(bi.getRGB(x-0, y-0) & 0xFFFFFF) != 0 &&
			(bi.getRGB(x+1, y-0) & 0xFFFFFF) != 0 &&
			(bi.getRGB(x-1, y+1) & 0xFFFFFF) != 0 &&
			(bi.getRGB(x-0, y+1) & 0xFFFFFF) != 0 &&
			(bi.getRGB(x+1, y+1) & 0xFFFFFF) != 0) {

			raster.setPixel(x, y, ones);
		    }
		    else {
			raster.setPixel(x, y, zeros); 
		    }
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
