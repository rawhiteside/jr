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

	public static PixelBlock constructBlank(Rectangle rect, int rgb) {
		BufferedImage bi = new BufferedImage(rect.width, rect.height, BufferedImage.TYPE_INT_RGB);
		for(int x = 0; x < rect.width; x++) {
			for(int y = 0; y < rect.height; y++) {
				bi.setRGB(x, y, rgb);
			}
		}
		return new PixelBlock(new Point(rect.x, rect.y), bi);
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
	 * Find and exact match for a template image in this larger image.
	 */
	public Point findTemplateExact(PixelBlock template) {
		return ImageUtils.findTemplateExact(m_bufferedImage, template.bufferedImage());
	}
	   
	/** 
	 * Search within self for the best mach for the subimage template.
	 */
	public Point findTemplateBest(PixelBlock template) {
		return findTemplateBest(template, Integer.MAX_VALUE);
	}
	public Point findTemplateBest(PixelBlock template, int bestDistSq) {
		PixelBlock brightTemplate = ImageUtils.brightness(template);
		PixelBlock brightImage = ImageUtils.brightness(this);
		Point bestPoint = null;


		int maxX = getWidth() - brightTemplate.getWidth();
		int maxY = getHeight() - brightTemplate.getHeight();
		for(int y = 0; y < maxY; y++) {
			for(int x = 0; x < maxX; x++) {
				int distSq = computeDist(brightImage, brightTemplate, x, y, bestDistSq);
				if (distSq < bestDistSq) {
					bestPoint = new Point(x, y);
					bestDistSq = distSq;
				}
			}
		}
		System.out.println("Best distsq: " + bestDistSq);
		return bestPoint;
	}

	private int computeDist(PixelBlock image, PixelBlock template, int xoff, int yoff, int bestSoFar) {
		BufferedImage biImage = image.bufferedImage();
		BufferedImage biTemplate = template.bufferedImage();
		int dist = 0;
		for(int y = 0; y < biTemplate.getHeight(); y++) {
			for(int x = 0; x < biTemplate.getWidth(); x++) {
				dist += Math.pow(biTemplate.getRGB(x, y) - biImage.getRGB(x + xoff, y + yoff), 2);
				if (dist > bestSoFar) {return dist;}
			}
		}
		return dist;
	}

	/**
	 * Coordinates are image coords, not screen coords.
	 */
	public Color getColor(int x, int y) {
		return new Color(m_bufferedImage.getRGB(x, y));
	}
	public Color getColor(Point p) {
		return getColor(p.x, p.y);
	}

	/**
	 * Returns a Color from the image, given the screen coords.
	 * It'd be Bad if those corrdinates weren't in the image.
	 */
	public Color getColorFromScreen(int x, int y) {
		x = x - m_origin.x;
		y = y - m_origin.y;
		return getColor(x, y);
	}
	public Color getColorFromScreen(Point p) {
		return getColorFromScreen(p.x, p.y);
	}


	/**
	 * Returns a pixel from the image, given the screen coords.
	 * It'd be Bad if those corrdinates weren't in the image.
	 */
	public int getPixelFromScreen(Point p) { return getPixelFromScreen(p.x, p.y); }
	public int getPixelFromScreen(int x, int y) {
		x = x - m_origin.x;
		y = y - m_origin.y;
		return getPixel(x, y);
	}

	/**
	 * returns an int with RRGGBB encoded.
	 */
	public int getPixel(int x, int y) {
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
	public int getPixel(Point p) {
		return getPixel(p.x, p.y);
	}


	public void setPixel(Point p, int rgb) {
		setPixel(p.x, p.y, rgb);
	}
	public void setPixel(int x, int y, int rgb) {
		m_bufferedImage.setRGB(x, y, rgb);
	}

	public void setPixelsFromScreenPoints(Point[] pts, int rgb) {
		for(int i = 0; i < pts.length; i++) {
			setPixel(fromScreen(pts[i]), rgb);
		}
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
	/*
	 * Return image coords from screen points.  No error checking,
	 * since I want it to just crash if I've made an error.
	 */
	public Point fromScreen(Point p) {
		return new Point(p.x - m_origin.x, p.y - m_origin.y);
	}

	public int getWidth() {
		return m_rect.width;
	}

	public int getHeight() {
		return m_rect.height;
	}

	/*
	 * Extract a sub-image.
	 */
	public PixelBlock slice(Rectangle rect) {
		PixelBlock pb = constructBlank(rect, 0x0);
		for(int x = 0; x < rect.width; x++) {
			for(int y = 0; y < rect.height; y++) {
				pb.setPixel(x, y, getPixel(x + rect.x, y + rect.y));
			}
		}
		return pb;
	}

	/*
	 *  Return a new rectangle that's all on the screen. 
	 */
	public static Rectangle clipToScreen(Rectangle rect) {
		Dimension dim = ARobot.sharedInstance().screenSize();
		Rectangle out = new Rectangle(rect);
		if (out.x < 0) {
			out.width += out.x;
			out.x = 0;
		}
		if (out.y < 0) {
			out.height += out.y;
			out.y = 0;
		}
		if (out.x + out.width > dim.width) { out.width = dim.width - out.x; }
		if (out.y + out.height > dim.height) { out.height = dim.height - out.y; }
		return out;
	}


	public void displayToUser() {
		ImagePanel.displayImage(m_bufferedImage, "Title goes here");
	}

	public void displayToUser(String title) {
		ImagePanel.displayImage(m_bufferedImage, title);
	}

	public String toString() {
		return "Origin = " + m_origin.toString() + ", rect = " + m_rect.toString();
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
