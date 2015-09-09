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
	if (s_instance == null) {
	    int screenWidth = new ARobot().screenSize().width;
	    Rectangle rect = WindowGeom.rectFromPoint(new Point(screenWidth/2, 50));
	    if (rect == null) {
		System.out.println("Failed to find clock loc window.");
	    } else {
		s_instance = new ClockLocWindow(rect);
	    }
	}
	return s_instance;
    }

    public Insets textInsets() {
	return new Insets(5, 5, 5, 5);
    }

    public TextReader textReader() {
	flushTextReader();
	return super.textReader();
    }

    public int[] coords() {
	String[] lines = readText().split("\n");
	String position = lines[lines.length - 1];
	String[] words = position.split(" ");
	int y = Integer.parseInt(words[words.length - 1]);
	String xstring = words[words.length - 2].replaceAll(",", "");
	int x = Integer.parseInt(xstring);
	return new int[] {x, y};
    }
}
