package org.foa;

import java.awt.*;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import java.io.*;

import org.foa.robot.ARobot;

public class PixelBlock extends ARobot {
	private BufferedImage m_bufferedImage;
	private Point m_origin;
	private Rectangle m_rect;

	public PixelBlock(Rectangle rect) {
		m_bufferedImage = createScreenCapture(rect);
		m_origin = new Point( rect.x, rect.y);
		m_rect = rect;
	}

	public PixelBlock(Point origin, BufferedImage img) {
		m_bufferedImage = img;
		m_origin = origin;
		m_rect = new Rectangle(m_origin.x, m_origin.y, img.getWidth(), img.getHeight());
	}

	public Rectangle rect() {
		return new Rectangle(m_rect);
	}

	public Point origin() {
		return new Point(m_origin);
	}

	public BufferedImage bufferedImage() {
		return m_bufferedImage;
	}

	/**
	 * Find a scaling that will give acceptable performance.  We
	 * compute the number of color diffs required, and reduce sizes
	 * until that count is below a threshold.  200M is too large.  52M
	 * was OK.
	 */
	private final static int MAX_DIFFS = 52000000;
	private int findScale(PixelBlock pb) {
		int scale = 1;
		Rectangle rectMe = rect();
		Rectangle rectOther = pb.rect();
		while(true) {
			long count = ((long)rectMe.width/scale) * (rectOther.width/scale) *
				(rectMe.height/scale) * (rectOther.height/scale);
			if (count < MAX_DIFFS) {
				System.out.println("Count of " + count + " accepted");
				break;
			}
			System.out.println("Count of " + count + " rejected");
			scale += 1;
		}
		System.out.println("Scale is " + scale);
		return scale;
	}

	/** 
	 * Search within self for the best mach for the subimage pb.
	 * Convert everything into HSB instead of RGB.  The HSB components
	 * get weighted, which makes things work better with the was
	 * lighting changes during the day.
	 */
	public Point findPatch(PixelBlock pb) {
		
		int scale = findScale(pb);
		BufferedImage biScene = ImageUtils.resize(bufferedImage(), scale);
		BufferedImage biPatch = ImageUtils.resize(pb.bufferedImage(), scale);
		
		
		int bestDiff = Integer.MAX_VALUE;
		Point bestOrigin = null;
		toHSB(biScene);
		toHSB(biPatch);
		for(int y = 0; y < biScene.getHeight() - biPatch.getHeight(); y++) {
			for(int x = 0; x < biScene.getWidth() - biPatch.getWidth(); x++) {
				int diff = weightedDiff(x, y, biScene, biPatch);
				if (bestDiff > diff) {
					bestDiff = diff;
					bestOrigin = new Point(x, y);
				}
			}
		}

		System.out.println("Best: " + bestDiff + ", best/pixel: " + (bestDiff/(biPatch.getWidth()*biPatch.getHeight())));
		bestOrigin.translate(biPatch.getWidth() / 2, biPatch.getHeight() / 2);
		return new Point(bestOrigin.x * scale, bestOrigin.y * scale);
	}

	/*
	 * Replace the RBG values with HSB values.
	 */
	private void toHSB(BufferedImage bi) {
		float[] hsb = new float[3];
		for(int i = 0; i < bi.getWidth(); i++) {
			for(int j = 0; j < bi.getHeight(); j++) {
				Color c = new Color(bi.getRGB(i, j));
				Color.RGBtoHSB(c.getRed(), c.getGreen(), c.getBlue(), hsb);
				int h = (int) (hsb[0] * 255);
				int s = (int) (hsb[1] * 255);
				int b = (int) (hsb[2] * 255);
				int hsbVal = (h << 16) | (s << 8) | b;
				bi.setRGB(i, j, hsbVal);
			}
		}
	}

	/* 
	 * Compute a weighted color diff between +this+ and the provided
	 * subimage pixel.  Should have HSB in the RGB slots of each pixel
	 * already.  Components get weighted with magic numbers from
	 * looking at the screen.
	 */
	private int weightedDiff(int x, int y, BufferedImage scene, BufferedImage patch) {
		int totalDiff = 0;
		for(int i = 0; i < patch.getWidth(); i++) {
			for(int j = 0; j < patch.getHeight(); j++) {
				Color c1 = new Color(patch.getRGB(i, j));
				Color c2 = new Color(scene.getRGB(x + i, y + j));
				totalDiff += weightedColorDiff(c1, c2);
			}
		}
		return totalDiff;
	}

	private int HUE_WEIGHT = 4;
	private int SAT_WEIGHT = 2;
	private int weightedColorDiff(Color c1, Color c2) {
		int hueDiff = c1.getRed() - c2.getRed();
		hueDiff = (hueDiff < 0 ? -hueDiff : hueDiff);
		int satDiff = c1.getGreen() - c2.getGreen();
		satDiff = (satDiff < 0 ? -satDiff : satDiff);
		int brightDiff = c1.getBlue() - c2.getBlue();
		brightDiff = (brightDiff < 0 ? -brightDiff : brightDiff);
		return (hueDiff << HUE_WEIGHT) + (satDiff << SAT_WEIGHT) + brightDiff;
	}

	/**
	 * Coordinates are image coords, not screen coords.
	 */
	public Color color(int x, int y) {
		return new Color(m_bufferedImage.getRGB(x, y));
	}
	public Color color(Point p) {
		return color(p.x, p.y);
	}

	/**
	 * Returns a Color from the image, given the screen coords.
	 * It'd be Bad if those corrdinates weren't in the image.
	 */
	public Color colorFromScreen(int x, int y) {
		x = x - m_origin.x;
		y = y - m_origin.y;
		return color(x, y);
	}
	public Color colorFromScreen(Point p) {
		return colorFromScreen(p.x, p.y);
	}


	/**
	 * Returns a pixel from the image, given the screen coords.
	 * It'd be Bad if those corrdinates weren't in the image.
	 */
	public int pixelFromScreen(Point p) { return pixelFromScreen(p.x, p.y); }
	public int pixelFromScreen(int x, int y) {
		x = x - m_origin.x;
		y = y - m_origin.y;
		return pixel(x, y);
	}

	/**
	 * returns an int with RRGGBB encoded.
	 */
	public int pixel(int x, int y) {
		try {
			return m_bufferedImage.getRGB(x, y) & 0xFFFFFF;
		}
		catch(Exception e) {
			int scr[] = toScreen(x, y);
			String msg = "Coordinate out of range. \nLocal coords: (" + x + ", " + y + ")\n" +
				"\n Screen coords: (" + scr[0] + ", " + scr[1] + ")";
			throw new ArrayIndexOutOfBoundsException(msg);
		}
	}
	public int pixel(Point p) {
		return pixel(p.x, p.y);
	}


	/*
	 * return screen coords for the provided image coords.
	 */
	public int[] toScreen(int x, int y) {
		Point p = toScreen(new Point(x, y));
		return new int[] {p.x, p.y};
	}

	public Point toScreen(Point p) {
		return new Point(m_origin.x + p.x, m_origin.y + p.y);
	}

	public int getWidth() {
		return m_rect.width;
	}

	public int getHeight() {
		return m_rect.height;
	}

	public void displayToUser(String title) {
		ImagePanel.displayImage(m_bufferedImage, title);
	}

	public void saveImage(String filename) {
		try {
			File f = new File(filename);
			ImageIO.write(m_bufferedImage, "png", f);
		} catch(IOException e) {
			System.out.println("image save failed:" + e.toString());
		}
	}

	public static PixelBlock loadImage(String filename) {
		BufferedImage b = null;
		try {
			b = ImageIO.read(new File(filename));
		} catch(IOException e) {
			System.out.println("image load failed:" + e.toString());
		}

		return new PixelBlock(new Point(0, 0), b);
	}
}
