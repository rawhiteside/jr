package org.foa;

import java.awt.Color;
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
