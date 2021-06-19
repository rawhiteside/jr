package org.foa.text;

import java.awt.Point;
import java.awt.Rectangle;
import java.util.*;

import java.util.regex.Pattern;
import java.util.regex.Matcher;
import org.foa.PixelBlock;

public class TextReader {
	public InkSpots[][] glyphs;
	public String[] lineText;
	private ITextHelper m_textHelper;
	private PixelBlock m_pb;

	public TextReader(PixelBlock pb, ITextHelper textHelper) {
		m_textHelper = textHelper;
		m_pb = pb;

		InkSpots bits = InkSpots.fromPixelBlock(m_pb, textHelper);

		InkSpots[] lines =  findLines(bits);
		glyphs = new InkSpots[lines.length][];

		for(int i = 0; i < lines.length; i++) {
			InkSpots[] glyphLine = findGlyphs(lines[i], textHelper.spacePixelCount());
			
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

	public PixelBlock getPixelBlock() {
		return m_pb;
	}
		

	/**
	 * Returns the window text as one big string.
	 */ 
	public String readText() {
		return readText(true);
	}
	// splitGlyphs(false) used by acquire-font
	public String readText(boolean splitGlyphs) {
		StringBuilder sb = new StringBuilder();
		for (InkSpots[] line : glyphs) {
			sb.append(readLine(line, splitGlyphs));
			sb.append("\n");
		}
		return sb.toString();
	}

	private String readLine(InkSpots[] glyphLine) {
		return readLine(glyphLine, true);
	}
	private String readLine(InkSpots[] glyphLine, boolean splitGlyphs) 
	{
		StringBuilder sb = new StringBuilder();
		for (InkSpots g : glyphLine) {
			sb.append(g.toString());
		}
		return sb.toString();
	}


	// Return a point to click on a line starting with the provided
	// text.
	public Point pointForLine(String menu) {
		InkSpots[] glyphs = findMatchingLine(menu);
		if(glyphs == null) {
			return null;
		}
		return centerOfGlyph(glyphs[0]);
	}

	private InkSpots[] findMatchingLine(String start) {
		for(int i = 0; i < lineText.length; i++) {
			if(lineText[i].startsWith(start)) {
				return glyphs[i];
			}
		}
		return null;
	}

	// Return a point to click on the provided word.
	// TODO:  Worry about multiple instances of the word?
	public Point pointForWord(String word) {
		String regex = "\\b" + word + "\\b";
		Pattern pattern = Pattern.compile(regex);
		for(int i = 0; i < lineText.length; i++) {
			String line = lineText[i];
			Matcher matcher = pattern.matcher(line);
			if(matcher.find()) {
				InkSpots g = glyphForIndex(i, matcher.start());
				if (g != null) { return centerOfGlyph(g);}
				else {return null;}
			}
		}
		return null;
	}

	private Point centerOfGlyph(InkSpots glyph) {
		int x = glyph.origin[0] + glyph.width / 2;
		int y = glyph.origin[1] + glyph.height / 2;
		return new Point(x, y);
	}

	public String textColor(String s) {
		InkSpots[] glyphs = findMatchingLine(s);
		if(glyphs == null) {
			return null;
		} else {
			return glyphs[0].color();
		}
	}


	// This is complicated by a single glyph being poossibly multiple
	// characters.
	public InkSpots glyphForIndex(int lineIndex, int charIndex) {
		InkSpots[] line = glyphs[lineIndex];
		int charCount = 0;
		for(int i = 0; i < line.length; i++) {
			String text = line[i].toString();
			charCount += text.length();
			if (charCount > charIndex) {return line[i];}
		}
		return null;
	}

	/**
	 * Strip off whitespace from around the glyph by removing any empty
	 * rows from the top and bottom. 
	 */
	private InkSpots trimGlyph(InkSpots g) {

		if (g.width == 0 || g.height == 0) {
			return g;
		}
		String emptyRow = makeRow(InkSpots.BACKGROUND_STR, g.width);
		int firstRow = 0;
		// Find the first non-empty row.
		while (g.rows[firstRow].equals(emptyRow)) {
			firstRow += 1;
			if (firstRow >= g.height) {
				return new InkSpots(g.origin, new String[0], m_textHelper);
			}
		}

		// Find the bottom-most non-blank row.
		int lastRow = g.height - 1;
		while(g.rows[lastRow].equals(emptyRow)) {
			lastRow -= 1;
			if (lastRow < firstRow || lastRow < 0) {
				return new InkSpots(g.origin, new String[0], m_textHelper);
			}
		}
		return g.slice(0, firstRow, g.width, lastRow - firstRow + 1);
	}

	/**
	 * We're give a "line", as identified by findLines().  We now
	 * split this into "glyphs", which are blots separated by empty
	 * vertical columns of pixels.
	 **/
	private InkSpots[] findGlyphs(InkSpots line, int spacePixelCount) {
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
			if ((x - xStart) >= spacePixelCount) {
				glyphs.add(line.slice(xStart, 0, 0, 0));
			}
		}
	}

	private boolean isEmptyColumn(InkSpots line, int x) {
		for(int y = 0; y < line.height; y++) {
			if (line.pixel(x, y) == InkSpots.INK_CHAR) {
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
	private InkSpots[] findLines(InkSpots area) {
		ArrayList<InkSpots> lines = new ArrayList<InkSpots>();
		String blankRow = makeRow(InkSpots.BACKGROUND_STR, area.width);
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
