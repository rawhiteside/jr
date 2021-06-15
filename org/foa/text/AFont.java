package org.foa.text;

import java.util.*;
import java.io.FileReader;
import java.io.FileWriter;
import java.util.Arrays;

import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.DumperOptions;


public class AFont {
	
	private static Map s_instances = new HashMap();
	private Map m_map;
	private static char[] m_bytes = { 0xbf };
	public static String UNKNOWN_GLYPH = new String(m_bytes);
	private String m_fontFile = null;
	//

	// Debug flag. Yeah.  I know about log files. Real Soon Now. 
	private boolean m_logging = false;

	public AFont(String filename) {
		m_fontFile = filename;

		FileReader r = null;
		Yaml yaml = new Yaml();
		try {
			r = new FileReader(filename);
			m_map = (Map) yaml.load(r);
			if(m_map == null) {m_map = new HashMap();}
			r.close();
		}
		catch(Exception e) {
			System.out.println("Exception: in AFont" + e.toString());
			e.printStackTrace();
		}
	}

	public static AFont instance(String filename) {
		AFont fontMap = (AFont) s_instances.get(filename);
		if(fontMap == null) {
			fontMap = new AFont(filename);
			s_instances.put(filename, fontMap);
		}
		return fontMap;
	}

	public void save() {
		try {
			FileWriter w = new FileWriter(m_fontFile);
			DumperOptions options = new DumperOptions();
			options.setIndent(2);
			options.setPrettyFlow(true);
			options.setDefaultFlowStyle(DumperOptions.FlowStyle.BLOCK);			
			Yaml yaml = new Yaml(options);
			try { yaml.dump(m_map, w); }
			finally { w.close(); }
		} catch (Exception e) {
			System.out.println(e.toString());
		}
	}

	public Map getFontMap() { return m_map;}
	
	public void add(String[] rows, String str) {
		ArrayList l = new ArrayList(Arrays.asList(rows));
		if (isDuplicate(l, str)) {
			return;
		}
		m_map.put(l, str);
		save();
	}

	public void remove(String[] rows) {
		ArrayList l = new ArrayList(Arrays.asList(rows));
		String s = (String) m_map.remove(l);
		if(s == null) {
			System.out.println("AFont.Remove returned null");
			System.out.println(String.join("\n", rows));
		} else {
			System.out.println("AFont.Remove returned: " + s);
		}
			
		save();
	}

	private void p(String output) {
		if (!m_logging) {return;}
		System.out.println(output);
	}


	public String textFor(String[] rows) {
		dumpGlyph(rows, "textFor this");
		ArrayList l = new ArrayList(Arrays.asList(rows));

		if (rows.length == 0) { return " ";}
		// If it's just a horizontal line that made it through the rule remove, then just make it a space.
		if (rows.length == 1 && rows[0].length() > 4) { return " ";}
		
		String val = (String) m_map.get(l);
		if (val != null) {
			return val;
		} else {
			dumpGlyph(rows, "This is complex");
			String text =  textForComplexGlyph(rows);
			if (text == null) {
				dumpGlyph(rows, "This was unknown");
				return UNKNOWN_GLYPH;
			} else {
				p("return complex: " + text);
				return text;
			}
		}
	}

	/**
	 * Some pairs of characters are jammed together.  For example,
	 * "th" is rendered as the two characters without any whitespace
	 * between.  This method, then, looks for some glyph that we *do*
	 * know about that matches exactly the leading part of the
	 * provided one.
	 *
	 * The goal here is to strip off known letters from the front of
	 * the provided glyph.
	 *
	 * This task is complicated by design choices I made early on
	 * (i.e., glyphs as an array of Strings.)
	 *
	 */
	private String textForComplexGlyph(String[] complexGlyph) {

		// Elements in keys are themselves arraylists of Strings.
		int bestCount = 0;
		String[] bestGlyph = null;
		String bestText = null;
		Iterator itr = m_map.keySet().iterator();
		while (itr.hasNext()) {
			ArrayList<String> key = (ArrayList<String>) itr.next();
			if (key.size() == 0) {continue;}

			String val = (String) m_map.get(key);
			String[] template = key.toArray(new String[0]);

			// If template is wider than complex, no joy
			if(template[0].length() >= complexGlyph[0].length()) {continue;}

			int matchCount = countWidthOfMatchingTemplate(template, complexGlyph);
			if (matchCount > bestCount) {
				bestCount = matchCount;
				bestGlyph = template;
				bestText = (String) m_map.get(key);
			}
		}
		// Did we find a match?
		if (bestCount > 0) {
			String[] newRows = stripMatchedRows(complexGlyph, bestCount);
			if (newRows[0].length() == 0) {
				return bestText;
			} else {
				p ("Complex found " + bestText + " and looking for more");
				return bestText + textFor(newRows);
			}
		}
		return null;
	}

	// Returns zero unless the template completely matches.  That is
	// it'll return either 0, or the width of the template.
	private int countWidthOfMatchingTemplate(String[] template, String[] complexGlyph) {

		// The two may not be the same height (taller letters, descenders).  Add rows of non-ink to
		// the top and/or the bottom of the template if necessary.
		// Return null if, during that process, we determine a match
		// is not possible.
		template = padIfNecessary(template, complexGlyph);
		if (template == null) { return 0; }

		int ncols = template[0].length();
		for(int icol = 0; icol < ncols; icol++) {
			for(int irow = 0; irow < template.length; irow++) {
				if (template[irow].charAt(icol) != complexGlyph[irow].charAt(icol)) {
					return 0;
				}
			}
		}
		p("match succeeded.");
		return ncols;
	}

	/**
	 * The template height may not match that of the complexGlyph:
	 * - Template may be taller:  No possible match, so return null.
	 * 
	 * Find the top left ink spot in template and complexGlyph.  Use
	 * this to determine whether need to pad at the top and/or at the
	 * bottom
	 * 
	 * - Template may be shorter (due to taller letters in complexGlyph):
	 *   Pad template at the top.
	 * - Template may be shorter (due to descenders in complexGlyph):
	 *   Pad template at the bottom.
	 * 
	 * If, after the upper and lower padding the template is taller
	 * than complexGlyph, then no match is possible.  Return null.
	 * 
	 */
	private String[] padIfNecessary(String[] template, String[] complexGlyph) {
		// Is the bare template taller?
		if (template.length > complexGlyph.length) { return null; }
		//
		// Find the first ink in the first column. 
		int complexOffset = findFirstInk(complexGlyph);
		int templateOffset = findFirstInk(template);
		//
		// If complex is *lower* than template, then it cannot match.
		if (complexOffset < templateOffset) { return null; }
		// 
		// If complex is *higher* than template, pad above.
		if (complexOffset > templateOffset) {
			int padAboveCount = complexOffset - templateOffset;
			// If this would make template *taller* that complex, the can't match.
			if(template.length + padAboveCount > complexGlyph.length) { return null; }
			template = padAbove(template, padAboveCount);
		}

		// Finally, if the heights are not the same, pad below.
		int count = complexGlyph.length - template.length;
		if (count != 0) { template = padBelow(template, count); }

		return template;
	}

	private int findFirstInk(String[] glyph) {
		char ink = InkSpots.INK_CHAR;
		for(int i = 0; i < glyph.length; i++) {
			if(glyph[i].charAt(0) == ink) { return i; }
		}
		// should not happen. 
		return -1;
	}

	// Add *count* pad whitespace rows to the top of template.
	private String[] padAbove(String[] template, int count) {
		ArrayList<String> alist = new ArrayList<String>();
		String pad = makePadString(template[0].length());
		for(int i = 0; i < count; i++) { alist.add(pad); }
		for(int i = 0; i < template.length; i++) { alist.add(template[i]); }
		return (String[]) alist.toArray(new String[0]);
	}

	// Add *count* pad whitespace rows to the bottom of template.
	private String[] padBelow(String[] template, int count) {
		ArrayList<String> alist = new ArrayList<String>();
		String pad = makePadString(template[0].length());
		for(int i = 0; i < template.length; i++) { alist.add(template[i]); }
		for(int i = 0; i < count; i++) { alist.add(pad); }
		return (String[]) alist.toArray(new String[0]);
	}

	private String makePadString(int width) {
		StringBuffer sb = new StringBuffer();
		for(int i = 0; i < width; i++) { sb.append(InkSpots.BACKGROUND_STR); }
		return sb.toString();
	}

	// Remove the leading count columns and return the result.
	// trim whitespace?
	private String[] stripMatchedRows(String[] complexGlyph, int count) {
		// remove the leading columns.
		String[] out = new String[complexGlyph.length];
		for(int i = 0; i < complexGlyph.length; i++) {
			out[i] = complexGlyph[i].substring(count);
		}

		dumpGlyph(out, "after strip");
		//
		// Check to see if top and/or bottom are all whitespace now. 
		String pad = makePadString(out[0].length());
		int topBlankCount = 0;
		for(int i = 0; i < out.length; i++) {
			if(!out[i].equals(pad)) { break; }
			else { topBlankCount += 1;}
		}

		int bottomBlankCount = 0;
		for(int i = 0; i < out.length; i++) {
			if(!out[out.length - 1 - i].equals(pad)) { break; }
			else { bottomBlankCount += 1;}
		}

		ArrayList<String> list = new ArrayList<String>();

		for(int i = topBlankCount; i < (out.length- bottomBlankCount); i++) {
			list.add(out[i]);
		}
		out = (String[]) list.toArray(new String[0]);
		dumpGlyph(out, "after trim");
		
		return out;
	}

	public void dumpGlyph(String[] glyph, String label) {
		if (!m_logging) {return;}
		System.out.println(label);
		for (int i = 0; i < glyph.length; i++) {
			System.out.println(glyph[i].replace(InkSpots.BACKGROUND_CHAR,' ').replace(InkSpots.INK_CHAR,'@'));
		}
	}

	
	private boolean isDuplicate(ArrayList rows, String str) {
		String val = (String) m_map.get(rows);
		if (val != null) {
			if (!str.equals(val)) {
				System.out.println("Inconsistent entries.  Pixels:");
				System.out.println(rows.toString());
				System.out.println("Old str: " + val + ", New str: " + str);
				return true;
			}
		}
		return false;
	}
}
