package org.foa.text;

import java.awt.Color;

public interface ITextHelper {
	// Detects whether a pixel is ink (instead of background)
	public boolean isInk(Color c, int x, int y);
	// How many bg pixels is a space character? 
	public int spacePixelCount();
	// Should remove rules?
	public boolean doRemoveRules();
}
