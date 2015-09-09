package org.foa;

import java.awt.*;
import java.awt.image.BufferedImage;

import org.foa.robot.ARobot;

public class PixelBlock extends ARobot {
    private BufferedImage m_bufferedImage;
    private Point m_origin;
    public PixelBlock(Rectangle rect) {
	m_bufferedImage = createScreenCapture(rect);
	m_origin = new Point( rect.x, rect.y);
    }

    public PixelBlock(Point origin, BufferedImage img) {
	m_bufferedImage = img;
	m_origin = origin;
    }

    public Point origin() {
	return m_origin;
    }
    public BufferedImage bufferedImage() {
	return m_bufferedImage;
    }
    /**
     * Coordinates are image coords, not screen coords.
     */
    public Color color(int x, int y) {
	return new Color(m_bufferedImage.getRGB(x, y));
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
	return m_bufferedImage.getRGB(x, y) & 0xFFFFFF;
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
	return m_bufferedImage.getWidth();
    }
    public int getHeight() {
	return m_bufferedImage.getHeight();
    }

}
