package org.foa.window;

import java.awt.*;
import java.util.Map;
import java.io.*;
import org.yaml.snakeyaml.Yaml;

import org.foa.text.TextReader;
import org.foa.text.AFont;
import org.foa.robot.ARobot;

public class ClockLocWindow extends AWindow {
	private Map m_backgroundColors = null;
	public ClockLocWindow(Rectangle rect) {
		super(rect);
		FileInputStream fis = null;
		try {
			fis = new FileInputStream("data/clockloc-green.yaml");
			// I don't know what I'm doing, so I have to skip the
			// first two lines of the yml file so it reads into Java.
			skipLine(fis);
			skipLine(fis);
		} catch(Exception e) {
			System.out.println("File trouble for clocklocwindow" );
			e.printStackTrace();
		}
		Yaml yaml = new Yaml();
		m_backgroundColors = (Map) yaml.load(fis);
		
	}
	// Find the clock loc window at its default place.
	// Not really a singleton anymore. 
	public static ClockLocWindow instance() {
		return createInstance();
	}

	private static void skipLine(FileInputStream fis) throws Exception {
		while(true) {
			int c = fis.read();
			if (c == 0x0a) {break;}
		}
	}
	private static ClockLocWindow createInstance() {
		int screenWidth = ARobot.sharedInstance().screenSize().width;

		//New system is 150 wide and 60 tall and not a rectangle but
		//  can probably be models as such.  It is immovable and 30
		//  pixels off the top on my system other milage may vary.
		Rectangle rect = new Rectangle(screenWidth/2 - 110, 37, 220, 48);

		return new ClockLocWindow(rect);
	}

	// ITextHelper methods
	public AFont getFontMap() {
		return AFont.instance();
	}
	public boolean isInk(Color c, int x, int y) {
		Integer rgb = new Integer(c.getRGB() & 0xFFFFFF);
		Object val = m_backgroundColors.get(rgb);
		return val == null;
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
