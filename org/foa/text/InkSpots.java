package org.foa.text;

import org.foa.robot.ARobot;
import java.util.ArrayList;
import java.awt.*;
import java.awt.image.BufferedImage;
import javax.imageio.*;
import java.io.*;

public class InkSpots {
    public int[] origin;
    public String[] rows;
    public int width;
    public int height;

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
     * The "pixel" for this class will be either the
     * character '0' or the character '1'.  Coordinates are local
     * to the block:  not screen coordinates.
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
	public String color() 
	{
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

    private static int RMIN = 0xca;
    private static int GMIN = 0xb4;
	private static int BMIN = 0x81;
	
	private static int RCoord = 0xf4;
	private static int GCoord = 0xf4;
	private static int BCoord = 0xf4;

    public static InkSpots fromScreen(Rectangle rect) {
		BufferedImage bi = new ARobot().createScreenCapture(rect);

		//Debug
		try {
			File outputfile = new File("saved.png");
		ImageIO.write(bi, "png", outputfile);
		} catch (Exception e) {
			//TODO: handle exception
		}
		

		ArrayList newRows = new ArrayList();
		for(int y = 0; y < rect.height; y++) {
			StringBuffer row = new StringBuffer();
			for(int x = 0; x < rect.width; x++) {
			Color c = new Color(bi.getRGB(x, y));
			if (Math.abs(c.getRed() - c.getGreen()) < 25 || Math.abs(c.getGreen() - c.getBlue()) < 25) 
			{
				row.append("0");
			}
			
			else if (c.getRed() < RMIN || c.getGreen() < GMIN || c.getBlue() < BMIN) {
				row.append("1");
			} 
			
			else {
				row.append("1");
			}
			}
			newRows.add(row.toString());
		}
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

		return new InkSpots(rect.x, rect.y, (String[]) newRows.toArray(new String[0]));
    }
}
