package org.foa.text;

import java.awt.Color;
import org.foa.PixelBlock;

public interface ITextHelper {
	// Only used by ClockLocWindow.
	public void startTextScan(PixelBlock pb);
	// Returns the font map to use.
	public AFont getFontMap();
	// Detects whether a pixel is ink (instead of background)
	public boolean isInk(Color c, int x, int y);
	// How many bg pixels is a space character? 
	public int spacePixelCount();
	// Should remove rules?
	public boolean doRemoveRules();
}
