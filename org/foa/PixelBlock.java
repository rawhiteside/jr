package org.foa;

import java.awt.*;
import java.awt.image.BufferedImage;

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
	 * Find a patch of color. Patch is size x size.
	 */
	public Point findPatch(Color cmin, Color cmax, int size) {
		for(int y = 0; y < m_rect.height - size; y++) {
			for(int x = 0; x < m_rect.width - size; x++) {
				Point p = matchingPatchCenter(x, y, cmin, cmax, size);
				if (p != null) {
					return p;
				}
			}
		}
		return null;
	}

	/* If (x, y) is the TL corner of the matching patch, return a
	 * point to the patch center.
	 */
	private Point matchingPatchCenter(int x, int y, Color cmin, Color cmax, int size) {
		for(int i = 0; i < size; i++) {
			for(int j = 0; j < size; j++) {
				Color c = color(x+i, y+j);
				if (c.getRed() < cmin.getRed() || c.getGreen() < cmin.getGreen() || c.getBlue() < cmin.getBlue() ||
					c.getRed() > cmax.getRed() || c.getGreen() > cmax.getGreen() || c.getBlue() > cmax.getBlue()) {
					return null;
				}
			}
		}
		return new Point(x + size / 2, y + size / 2);
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
}
