package org.foa.text;

import org.foa.robot.ARobot;
import org.foa.PixelBlock;
import java.util.ArrayList;
import java.awt.*;
import java.awt.image.BufferedImage;
import javax.imageio.*;
import java.io.*;

public class InkSpots {
	public static String INK_STR = "@"; 
	public static char INK_CHAR = INK_STR.charAt(0);
 	public static String BACKGROUND_STR = " "; 
 	public static char BACKGROUND_CHAR = BACKGROUND_STR.charAt(0);

	public int[] origin;
	public String[] rows;
	public int width;
	public int height;
	private ITextHelper m_textHelper;

	// Set a debug output flag.  We don't need no steenkin' properties
	// file.
	private static boolean s_debug = false;

	public InkSpots(int[] origin, String[] irows, ITextHelper textHelper) {
		m_textHelper = textHelper;
		this.origin = origin;
		this.rows = irows;
		this.height = irows.length;
		if (rows.length == 0) {
			this.width = 0;
		} else {
			this.width = irows[0].length();
		}
	}

	public InkSpots(int x, int y, String[] irows, ITextHelper textHelper) {
		this(new int[] {x, y}, irows, textHelper);
	}
	/**
	 * The "pixel" for this class will be either the character '@'
	 * (ink) or the character ' ' (background).  Coordinates are local
	 * to the block: not screen coordinates.
	 */
	public char pixel(int x, int y) {
		return this.rows[y].charAt(x);
	}

	public InkSpots create(int[] origin, String[] irows) {
		return new InkSpots(origin, irows, m_textHelper);
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
		return m_textHelper.getFontMap().textFor(this.rows);
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
		PixelBlock pb = new PixelBlock(rect);

		textHelper.startTextScan(pb);
		ArrayList newRows = new ArrayList();
		for(int y = 0; y < rect.height; y++) {
			StringBuffer row = new StringBuffer();
			for(int x = 0; x < rect.width; x++) {
				Color c = pb.getColor(x, y);
				if (textHelper.isInk(c, x, y)) {
					row.append(INK_STR); 
				} else {
					row.append(BACKGROUND_STR); 
				}
			}
			newRows.add(row.toString());
		}
		if(textHelper.doRemoveRules()) {
			newRows = RuleRemover.removeRules(newRows, 14);
		}

		return new InkSpots(rect.x, rect.y, (String[]) newRows.toArray(new String[0]), textHelper);
	}

}
