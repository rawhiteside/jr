package org.foa.text;

import java.util.ArrayList;

public class RuleRemover {

	// Elements of the array list are strings of 0/1.  0 (black) is
	// ink.
	public static ArrayList removeRules(ArrayList<String> rows, int max) {
		byte[][] bytes = toByteArray(rows);
		//dump(bytes, "Start");
		// Remove the vertical rules first, to transpose first. 

		bytes = transpose(bytes);
		removeHRules(bytes, max);

		bytes = transpose(bytes);
		removeHRules(bytes, max);

		ArrayList<String> out = new ArrayList<String>();
		for(int i = 0; i < bytes.length; i++) {
			out.add(new String(bytes[i]));
		}
		return out;
	}

	private static void dump(byte[][] bytes, String title) {
		System.out.println("-----------------" + title);
		for(int i = 0; i < bytes.length; i++) {
			String s = new String(bytes[i]);
			s = s.replaceAll(InkSpots.BACKGROUND_STR, " ").replaceAll(InkSpots.INK_STR, "@");
			System.out.println(s);
		}
	}

	// Turn the array of Strings into a byte[][]
	public static byte[][] toByteArray(ArrayList<String> rows) {
		byte[][] bytes = new byte[rows.size()][];
		for (int i = 0; i < rows.size(); i++) {
			bytes[i] = rows.get(i).getBytes();
		}
		return bytes;
	}

	// Remove all the horizontal rules.
	public static void removeHRules(byte[][] bytes, int maxlen) {
		for(int i = 0; i < bytes.length; i++) {
			byte[] line = bytes[i];
			int first = -1;
			int last = 0;

			for(int j = 0; j < line.length; j++) {
				// It's ink
				if (line[j] == InkSpots.INK_CHAR) {
					if(first == -1) { first = j; }
					last = j;
				}
				// It's not ink.  See if we're at the end of a rule.
				else {
					if(first > -1 && (last - first + 1) > maxlen) {
						// Rule found.  Clobber it.
						for(int k = first; k <= last; k++) { line[k] = (byte) InkSpots.BACKGROUND_CHAR; }
						first = -1;
					}
					// A line, but not a rule.
					else { first = -1; }
				}
			}
			if(first > -1 && (last - first + 1) > maxlen) {
				// Rule found.  Clobber it.
				for(int k = first; k <= last; k++) { line[k] = (byte) InkSpots.BACKGROUND_CHAR; }
				first = -1;
			}
		}
	}

	public static byte[][] transpose(byte[][] bytes) {
		byte[][] obytes = new byte[bytes[0].length][bytes.length];
		for(int i = 0; i < bytes.length; i++) {
			for(int j = 0; j < bytes[0].length; j++) {
				obytes[j][i] = bytes[i][j];
			}
		}
		return obytes;
	}
}
