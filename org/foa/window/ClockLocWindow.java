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
	Rectangle rect = WindowGeom.rectFromPoint(new Point(screenWidth/2, 50));
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
	    try { return attemptCoords(text); }
	    catch (NumberFormatException e) {
		System.out.println("Coords failed with \"" + text + "\" Retrying.");
	    }
	    sleepSec(0.1);
	    ClockLocWindow.resetInstance();
	}
	return null;
    }

    private int[] attemptCoords(String text) {
	String[] lines = text.split("\n");
	String position = lines[lines.length - 1];
	String[] words = position.split(" ");
	int y = Integer.parseInt(words[words.length - 1]);
	String xstring = words[words.length - 2].replaceAll(",", "");
	int x = Integer.parseInt(xstring);
	return new int[] {x, y};
    }
	
}
