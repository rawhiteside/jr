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


	public void setPixel(Point p, int val) {
		setPixel(p.x, p.y, val);
	}
	public void setPixel(int x, int y, int val) {
		m_bufferedImage.setRGB(x, y, val);
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
