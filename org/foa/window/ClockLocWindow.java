package org.foa.window;

import java.awt.*;

import org.foa.text.TextReader;
import org.foa.robot.ARobot;

public class ClockLocWindow extends AWindow {

	public ClockLocWindow(Rectangle rect) {
		super(rect);
	}
	// Find the clock loc window at its default place.
	// Not really a singleton anymore. 
	public static ClockLocWindow instance() {
		return createInstance();
	}

	private static ClockLocWindow createInstance() {
		int screenWidth = new ARobot().screenSize().width;

		//Method used to find cloc pre-T9
		//Rectangle rect = WindowGeom.rectFromPoint(new Point(screenWidth/2, 50));
		//New system is 150 wide and 60 tall and not a rectangle but can probably be models as such.
		//  It is immovable and 30 pixels off the top on my system other milage may vary.
		Rectangle rect = new Rectangle(screenWidth/2 - 110, 37, 220, 39);
		if (rect == null) {
			System.out.println("Failed to find clock loc window.");
			return null;
		} else {
			return new ClockLocWindow(rect);
		}
	}

	public Insets textInsets() {
		return new Insets(5, 5, 5, 5);
	}

	// ITextHelper methods
	private int m_spacePixelCount = 5;
	public boolean isInk(Color c) {
		// Backgrounds:
		// Kush: b < 50
		// Mesh: r == 0
		// Kyksos: b < 50
		if (c.getBlue() < 50 || c.getRed() < 5) {
			return false;
		} else {
			return true;
		}

	}
	public void setSpacePixelCount(int count) {
		m_spacePixelCount = count;
	}

	public int spacePixelCount() {
		return m_spacePixelCount;
	}

	public TextReader textReader() {
		flushTextReader();
		return super.textReader();
	}

	public String dateTime() {
		String text = readText();
		String[] lines = text.split("\n");
		return lines[0];
	}

	public String date() {
		String[] fields = dtFields();
		return fields[0] + "," + fields[1];
	}

	public String time() {
		String[] fields = dtFields();
		return fields[2].trim();
	}

	private String[] dtFields() {
		String dt = dateTime();
		return dt.split(",");
	}

	public int[] coords() {
		String text = ClockLocWindow.instance().readText();
		try { 
			return attemptCoords(text); 
		}
		catch (NumberFormatException e) {
			System.out.println("Coords failed with text:\"" + text + "\".");
		}
		catch (Exception e) {
			System.out.println("General exception of " + e.toString());
			System.out.println("Text was:" + text);
		}
		sleepSec(0.1);
		return null;
	}

	private int[] attemptCoords(String text) {
		String[] lines = text.split("\n");
		String position = lines[lines.length - 1];
		String[] chunks = position.split(":");
		String[] words = chunks[1].split("[.,]");
		int y = Integer.parseInt(words[words.length - 1].replaceAll(" ",""));

		String xstring = words[words.length - 2].replaceAll(",", "").replaceAll(" ","");
		int x = Integer.parseInt(xstring);
		return new int[] {x, y};
	}
	
}
