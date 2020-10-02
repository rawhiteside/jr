package org.foa.text;

import org.foa.robot.ARobot;
import java.util.ArrayList;
import java.awt.*;
import java.awt.image.BufferedImage;
import javax.imageio.*;
import java.io.*;

public class InkSpots {
	//
	// Poor decision sometime in the past. Seemed like a good idea at the time. 
	public static String INK_CHAR = "0";   // 0 = black = ink
	public static String BACKGROUND_CHAR = "1";  // 1 = white = background

	public int[] origin;
	public String[] rows;
	public int width;
	public int height;

	// Set a debug output flag.  We don't need no steenkin' properties
	// file.
	private static boolean s_debug = false;

	public InkSpots(int[] origin, String[] irows) {
		this.origin = origin;
		this.rows = irows;
		this.height = irows.length;
		if (rows.length == 0) {
			this.width = 0;
		} else {
			this.width = irows[0].length();
		}
	}

	public InkSpots(int x, int y, String[] irows) {
		this.origin = new int[] {x, y};
		this.rows = irows;
		this.height = irows.length;
		if (rows.length == 0) {
			this.width = 0;
		} else {
			this.width = irows[0].length();
		}
	}
	/**
	 * The "pixel" for this class will be either the character '0' (==
	 * black == ink) or the character '1' (== white == background).
	 * Coordinates are local to the block: not screen coordinates.
	 */
	public char pixel(int x, int y) {
		return this.rows[y].charAt(x);
	}

	public InkSpots create(int[] origin, String[] irows) {
		return new InkSpots(origin, irows);
	}

	public int[] toScreen(int x, int y) {
		return new int[] {
			x + this.origin[0], y + this.origin[1],
		};
	}

	public String toString() {
		if (this.width > 15 && this.height <= 3) {
			return "-----";
		}
		return AFont.instance().textFor(this.rows);
	}

	/**
	 * Extract a sub-rectangle.
	 */
	public InkSpots slice(int x, int y, int iwidth, int iheight) {
		if (iwidth == 0 || iheight == 0) {
			return create(toScreen(x, y), new String[0]);
		}
		ArrayList<String> newRows = new ArrayList<String>();
		for(int h = 0; h < iheight; h++) {
			if ((h + y) >= this.rows.length){
				break;
			}
			newRows.add(this.rows[h+y].substring(x, x+iwidth));
		}
		return create(toScreen(x, y), (String[]) newRows.toArray(new String[0]));
	}

	/**
	 * Returns one of "red", "green", "blue", "unknown". This is the color
	 * of the text in the block. 
	 */
	public String color() {
		Rectangle rect = new Rectangle(this.origin[0], this.origin[1], this.width, this.height);
		BufferedImage bi = new ARobot().createScreenCapture(rect);

		for(int y = 0; y < this.height; y++) {
			for(int x = 0; x < this.width; x++) {
				Color c = new Color(bi.getRGB(x, y));
				if (c.getRed() == 255 && c.getGreen() == 0 && c.getBlue() == 0) {
					return "red";
				}
				if (c.getRed() == 0 && c.getGreen() == 255 && c.getBlue() == 0) {
					return "green";
				}
				if (c.getRed() == 0 && c.getGreen() == 0 && c.getBlue() == 255) {
					return "blue";
				}
			}
		}
		return "unknown";
	}

	public static InkSpots fromScreen(Rectangle rect, ITextHelper textHelper) {
		BufferedImage bi = new ARobot().createScreenCapture(rect);

		// Debug
		if (s_debug) {
			try {
				File outputfile = new File("saved.png");
				ImageIO.write(bi, "png", outputfile);
			} catch (Exception e) {
				//TODO: handle exception
			}
		}

		ArrayList newRows = new ArrayList();
		for(int y = 0; y < rect.height; y++) {
			StringBuffer row = new StringBuffer();
			for(int x = 0; x < rect.width; x++) {
				Color c = new Color(bi.getRGB(x, y));
				if (textHelper.isInk(c)) {
					row.append(INK_CHAR); 
				} else {
					row.append(BACKGROUND_CHAR); 
				}
			}
			newRows.add(row.toString());
		}
		newRows = RuleRemover.removeRules(newRows, 12);

		if (s_debug) {
			try {
				BufferedWriter writer = new BufferedWriter(new FileWriter("debug.txt"));
			
				for (int debugCount = 0; debugCount < newRows.size(); debugCount++)
					{
						writer.write(newRows.get(debugCount).toString());
						writer.newLine();
					}
				writer.close();
			} catch (Exception e) {
				//TODO: handle exception
			}
		}
		return new InkSpots(rect.x, rect.y, (String[]) newRows.toArray(new String[0]));
	}

}
