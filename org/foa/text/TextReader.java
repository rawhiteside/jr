package org.foa.text;

import java.awt.Rectangle;
import java.util.*;

public class TextReader {
    public InkSpots[] lines;
    public InkSpots[][] glyphs;
    public String[] lineText;

    public TextReader(Rectangle rect) {
		InkSpots bits = InkSpots.fromScreen(rect);
		InkSpots[] lines =  findLines(bits);
		glyphs = new InkSpots[lines.length][];

		for(int i = 0; i < lines.length; i++) {
			InkSpots[] glyphLine = findGlyphs(lines[i]);
			
			for (int j = 0; j < glyphLine.length; j++) {
			glyphLine[j] = trimGlyph(glyphLine[j]);
			}
			glyphs[i] = glyphLine;
		}
		lineText = new String[glyphs.length];
		for(int i = 0; i < glyphs.length; i++) {
			lineText[i] = readLine(glyphs[i]);
		}
    }

    /**
     * Returns the window text as one big string.
     */ 
    public String readText() 
	{
		StringBuilder sb = new StringBuilder();
		for (InkSpots[] line : glyphs) {
			sb.append(readLine(line));
			sb.append("\n");
		}
		return sb.toString();
	}

	private String readLine(InkSpots[] glyphLine) 
	{
		StringBuilder sb = new StringBuilder();
		for (InkSpots g : glyphLine) {
			sb.append(g.toString());
		}
		return sb.toString();
    }

    /**
     * Strip off whitespace from around the glyph by removing any empty
     * rows from the top and bottom. 
     */
    public InkSpots trimGlyph(InkSpots g) {

		if (g.width == 0 || g.height == 0) {
			return g;
		}
		String emptyRow = makeRow("1", g.width);
		int firstRow = 0;
		// Find the first non-empty row.
		while (g.rows[firstRow].equals(emptyRow)) {
			firstRow += 1;
			if (firstRow >= g.height) {
			return new InkSpots(g.origin, new String[0]);
			}
		}

		// Find the bottom-most non-blank row.
		int lastRow = g.height - 1;
		while(g.rows[lastRow].equals(emptyRow)) {
			lastRow -= 1;
			if (lastRow < firstRow || lastRow < 0) {
			return new InkSpots(g.origin, new String[0]);
			}
		}
		return g.slice(0, firstRow, g.width, lastRow - firstRow + 1);
    }

    /**
     * We're give a "line", as identified by findLines().  We now
     * split this into "glyphs", which are blots separated by empty
     * vertical columns of pixels.
     **/
    public InkSpots[] findGlyphs(InkSpots line) {
		ArrayList<InkSpots> glyphs = new ArrayList<InkSpots>();
		int x = 0;
		if (x >= line.width) {
			return new InkSpots[0];
		}
		// Skip leading whitespace.
		while (isEmptyColumn(line, x)) {
			x += 1;
			if (x >= line.width) {
			return new InkSpots[0];
			}
		}
		while (true) {
			// Extract a glyph.
			int xStart = x;
			while(!isEmptyColumn(line, x)) {
			x += 1;
			if (x >= line.width) {
				break;
			}
			}
			int xEnd = x;
			glyphs.add(line.slice(xStart, 0, xEnd - xStart, line.height));
			if (x >= line.width) {
			return (InkSpots[]) glyphs.toArray(new InkSpots[0]);
			}
			// And skip past whitespace.
			xStart = x;
			while (isEmptyColumn(line, x)) {
			x += 1;
			if (x >= line.width) {
				return (InkSpots[]) glyphs.toArray(new InkSpots[0]);
			}
			}
			// Insert a space glyph if there was lots of whitespace.
			if ((x - xStart) >= 3) {
			glyphs.add(line.slice(xStart, 0, 0, 0));
			}
		}
    }

    private boolean isEmptyColumn(InkSpots line, int x) {
	for(int y = 0; y < line.height; y++) {
	    if (line.pixel(x, y) == '0') {
		return false;
	    }
	}
	return true;
    }

    /*
     * Return a string formed from +len+ copies of the string +s+.
     */
    private String makeRow(String s, int len) {
	StringBuilder sb = new StringBuilder();
	for(int i = 0; i < len; i++) {sb.append(s);}
	return sb.toString();
    }

    /**
     * Split the bitmap into lines.  A "line" is a contiguous group of
     * non-blank rows.
     */
    public InkSpots[] findLines(InkSpots area) {
	ArrayList<InkSpots> lines = new ArrayList<InkSpots>();
	String blankRow = makeRow("1", area.width);
	int irow = 0;
	while (true) {
	    // Skip blank lines.
	    while (area.rows[irow].equals(blankRow)) {
		irow += 1;
		if (irow >= area.height) {
		    return (InkSpots[]) lines.toArray(new InkSpots[0]);
		}
	    }
	    // Now, accumulate non-blank lines.
	    int ifirst = irow;
	    while (!area.rows[irow].equals(blankRow)) {
		irow += 1;
		if (irow >= area.height) {
		    break;
		}
	    }
	    // And extract the line.
	    lines.add(area.slice(0, ifirst, area.width, irow - ifirst));
	    if (irow >= area.height) {
		return (InkSpots[]) lines.toArray(new InkSpots[0]);
	    }
	}
    }
}
