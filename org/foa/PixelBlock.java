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
	 * Search within self for the best mach for the subimage pb.
	 * Convert everything into HSB instead of RGB.  The HSB components
	 * get weighted, which makes things work better with the was
	 * lighting changes during the day.
	 */
	public Point findPatch(PixelBlock pb) {
		int bestDiff = Integer.MAX_VALUE;
		int diff = 0;
		Point bestOrigin = null;

		toHSB(this);
		toHSB(pb);
		for(int y = 0; y < m_rect.height - pb.getHeight(); y++) {
			// if (y % 10 == 0) { System.out.println("y = " + y);}
			for(int x = 0; x < m_rect.width - pb.getWidth(); x++) {
				diff = weightedDiff(x, y, pb, bestDiff);
				if (bestDiff > diff) {
					bestDiff = diff;
					bestOrigin = new Point(x, y);
				}
			}
		}

		System.out.println("Best: " + bestDiff + ", best/pixel: " + (bestDiff/(pb.getWidth()*pb.getHeight())));

		bestOrigin.translate(pb.getWidth() / 2, pb.getHeight() / 2);
		return bestOrigin;
	}

	/*
	 * Replace the RBG values with HSB values.
	 */
	private void toHSB(PixelBlock pb) {
		float[] hsb = new float[3];
		BufferedImage bi = pb.bufferedImage();
		for(int i = 0; i < pb.getWidth(); i++) {
			for(int j = 0; j < pb.getHeight(); j++) {
				Color c = pb.color(i, j);
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
	private int weightedDiff(int x, int y, PixelBlock pb, int bestSoFar) {
		int totalDiff = 0;
		for(int i = 0; i < pb.getWidth(); i++) {
			for(int j = 0; j < pb.getHeight(); j++) {
				Color c1 = pb.color(i, j);
				Color c2 = this.color(x + i, y + j);
				totalDiff += weightedColorDiff(c1, c2);
				if(totalDiff > bestSoFar) {
					return totalDiff;
				}
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
