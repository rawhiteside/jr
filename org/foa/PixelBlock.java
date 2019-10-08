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
	private static int[][] s_diffSq = null;

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

	private int[][] diffSqLookup() {
		if (s_diffSq == null) {
			s_diffSq = new int[256][256];
			for(int i = 0; i < 256; i++) {
				for(int j = 0; j < 256; j++) {
					s_diffSq[i][j] = (i - j) * (i - j);
				}
			}
		}
		return s_diffSq;
	}

	/** 
	 * Search within self for the best mach for the subimage pb
	 */
	public Point findPatch(PixelBlock pb) {
		double bestDeltaSq = Double.MAX_VALUE;
		Point bestOrigin = null;
		System.out.println("The patcch: " + pb.rect().toString());
		for(int y = 0; y < m_rect.height - pb.getHeight(); y++) {
			//System.out.println("y val " + y);
			for(int x = 0; x < m_rect.width - pb.getWidth(); x++) {
				// System.out.println("x val " + x);
				double deltaSq = deltaSquared(x, y, pb, bestDeltaSq);
				if (deltaSq < bestDeltaSq) {
					bestDeltaSq = deltaSq;
					// System.out.println("New best: " + bestDeltaSq);
					bestOrigin = new Point(x, y);
				}
			}
		}

		System.out.println("Best: " + bestDeltaSq);

		bestOrigin.translate(pb.getWidth() / 2, pb.getHeight() / 2);
		return bestOrigin;
	}

	/* Compute the average color distance between the two images.
	 */
	private double deltaSquared(int x, int y, PixelBlock pb, double bestSoFar) {
		bestSoFar = bestSoFar * (pb.getWidth() * pb.getHeight());
		double totalDist = 0;
		for(int i = 0; i < pb.getWidth(); i++) {
			//System.out.println("i val " + i);
			for(int j = 0; j < pb.getHeight(); j++) {
				Color c1 = pb.color(i, j);
				Color c2 = this.color(x + i, y + j);
				totalDist += colorDistanceSq(c1, c2);
				if(totalDist > bestSoFar) {
					return totalDist/ (pb.getWidth() * pb.getHeight());
				}
			}
		}
		return totalDist / (pb.getWidth() * pb.getHeight());
	}

	private double colorDistanceSq(Color c1, Color c2) {
		int mask = 0xff;
		int v1 = c1.getRGB();
		int v2 = c2.getRGB();
		int[][] table = diffSqLookup();
		int rdiffSq = table[v1 & mask][v2 & mask];
		v1 = v1 >> 8;
		v2 = v2 >> 8;
		int gdiffSq = table[v1 & mask][v2 & mask];
		v1 = v1 >> 8;
		v2 = v2 >> 8;
		int bdiffSq = table[v1 & mask][v2 & mask];

		return rdiffSq + gdiffSq + bdiffSq;
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
