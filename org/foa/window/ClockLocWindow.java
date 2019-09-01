package org.foa.window;

import java.awt.*;

import org.foa.text.TextReader;
import org.foa.robot.ARobot;

public class ClockLocWindow extends AWindow {
    private static ClockLocWindow s_instance = null;

    public ClockLocWindow(Rectangle rect) {
	super(rect);
    }
    // Find the clock loc window at its default place.
    public static ClockLocWindow instance() {
	if (s_instance == null) { s_instance = createInstance(); }
	return s_instance;
    }

    public static ClockLocWindow resetInstance() {
	s_instance = createInstance();
	return s_instance;
    }

    private static ClockLocWindow createInstance() {
		int screenWidth = new ARobot().screenSize().width;

		//Method used to find cloc pre-T9
		//Rectangle rect = WindowGeom.rectFromPoint(new Point(screenWidth/2, 50));
		//New system is 150 wide and 60 tall and not a rectangle but can probably be models as such.
		//  It is immovable and 30 pixels off the top on my system other milage may vary.
		System.out.println("Creating new cloc manual window");
		Rectangle rect = new Rectangle(screenWidth/2 - 100, 30, 200, 60);
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
	// All this error catching is because of a really
	// low-probability failure that I don't understand.  Perhaps
	// the output here will let me figure it out.
		for(int i = 0; i < 5; i++) {
			String text = ClockLocWindow.instance().readText();
			System.out.println("Text clock debug : " + text);
			try 
			{ 
				return attemptCoords(text); 
			}
			catch (NumberFormatException e) 
			{
				System.out.println("Coords failed with \"" + text + "\" Retrying.");
			}
			catch (Exception e)
			{
				System.out.println("General exception of " + e.toString());
				System.out.println("Text of " + text);
			}
			sleepSec(0.1);
			ClockLocWindow.resetInstance();
		}
		return null;
    }

    private int[] attemptCoords(String text) {
		String[] lines = text.split("\n");
		String position = lines[lines.length - 2];
		String[] chunks = position.split(":");
		String[] words = chunks[1].split(" ");
		int y = Integer.parseInt(words[words.length - 1]);
		String xstring = words[words.length - 2].replaceAll(",", "");
		int x = Integer.parseInt(xstring);
		return new int[] {x, y};
    }
	
}
