package org.foa.text;

import java.awt.Color;

public interface ITextHelper {
	// Detects whether a pixel is ink (instead of background)
	public boolean isInk(Color c);
	// How many bg pixels is a space character? 
	public int spacePixelCount();
}
