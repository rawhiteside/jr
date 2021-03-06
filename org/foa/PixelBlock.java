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

	public PixelBlock (PixelBlock pb) {
		m_bufferedImage =
			new BufferedImage(pb.m_rect.width, pb.m_rect.height, BufferedImage.TYPE_INT_RGB);
		m_rect = new Rectangle(pb.m_rect);
		for(int x = 0; x < m_rect.width; x++) {
			for(int y = 0; y < m_rect.height; y++) {
				m_bufferedImage.setRGB(x, y, pb.m_bufferedImage.getRGB(x, y));
			}
		}
	}

	public static PixelBlock fullScreen() {
		Dimension dim = s_screenDim;
		return new PixelBlock(new Rectangle(0, 0, dim.width, dim.height));
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

	// Why did I do this?  
	public Rectangle rect() { return getRect();}
	public Rectangle getRect() { return new Rectangle(m_rect); }

	public Point getOrigin() { return new Point(m_origin);}
	public Point origin() { return getOrigin();}

	public BufferedImage bufferedImage() {
		return m_bufferedImage;
	}

	/**
	 * Find the bext fuzzy match for a template image in this larger image. 
	 * @param threshold - A max per-pixel color difference.  The
	 * *distance* here is defined as the max(delta(r), delta(g),
	 * delta(b)).
	 */
	public Point findTemplateBest(PixelBlock template, int threshold) {
		return findTemplateBest(template, threshold, getRect());
	}

	public Point findTemplateBest(PixelBlock template, int threshold, Rectangle rect) {
		return ImageUtils.findTemplateBest(m_bufferedImage, template.bufferedImage(), threshold, rect);
	}
	/**
	 * Find and exact match for a template image in this larger image.
	 */
	public Point findTemplateExact(PixelBlock template) {
		return ImageUtils.findTemplateExact(m_bufferedImage, template.bufferedImage());
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

	/**
	 * Copy pixels into this from pb. 
	 */
	public void copyPixels(Point[] pts, PixelBlock pb) {
		for(int i = 0; i < pts.length; i++) { setPixel(pts[i], pb.getPixel(pts[i])); }
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
