package org.foa.window;

import org.foa.robot.ARobot;
import java.awt.*;

public abstract class WindowGeom extends ARobot {
	public abstract Rectangle rectFromPoint(Point p);
}
