package org.foa.window;

import java.awt.*;
import java.util.Map;
import java.io.*;
import org.yaml.snakeyaml.Yaml;

import org.foa.PixelBlock;
import org.foa.text.TextReader;
import org.foa.text.AFont;
import org.foa.robot.ARobot;

public class ClockLocWindow extends AWindow {
	private static String[] s_bgImageNames = {
		"ClockLoc-green.png",
		"ClockLoc-orange.png",
	};
	private static PixelBlock[] s_images = new PixelBlock[s_bgImageNames.length];
	static {
		for(int i = 0; i < s_bgImageNames.length; i++) {
			s_images[i] = PixelBlock.loadImage("images/" + s_bgImageNames[i]);
		}
	}
		
	public ClockLocWindow() {
		super();
		int screenWidth = ARobot.sharedInstance().screenSize().width;

		//New system is 150 wide and 60 tall and not a rectangle but
		//  can probably be models as such.  It is immovable and 30
		//  pixels off the top on my system other milage may vary.
		Rectangle rect = new Rectangle(screenWidth/2 - 110, 37, 220, 48);
		setRect(rect);
		
	}
	// Find the clock loc window at its default place.
	// Not really a singleton anymore. 
	public static ClockLocWindow instance() {
		return new ClockLocWindow();
	}

	// ITextHelper methods
	public AFont getFontMap() {
		return AFont.instance("data/clockloc-font.yaml");
	}

	// XXX
	public boolean isInk(Color c, int x, int y) {
		return false;
	}

	public boolean doRemoveRules() {
		return false;
	}

	private int m_spacePixelCount = 7;
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
		return dt.split("\\.");
	}

	public int[] coords() {
		String text = readText();
		try { 
			return attemptCoords(text); 
		}
		catch (NumberFormatException e) {
			System.out.println("Coords failed with text:\"" + text + "\".");
			System.out.println("Exception of " + e.toString());
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

		// Not stripping rules, we get an extra empty line at the top. 
		String position = lines[2];
		String[] chunks = position.split(":");
		String[] words = chunks[1].trim().split("[.,]");
		int y = Integer.parseInt(words[words.length - 1].replaceAll(" ",""));

		String xstring = words[words.length - 2].replaceAll(",", "").replaceAll(" ","");
		int x = Integer.parseInt(xstring);
		return new int[] {x, y};
	}
	
}
