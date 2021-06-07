package org.foa.window;
import org.foa.text.*;
import org.foa.PixelBlock;
import java.awt.Color;


public class PinnableTextHelper implements ITextHelper{
	private int m_spacePixelCount = 3;
	
	public PinnableTextHelper() { }

	public AFont getFontMap() {
		return AFont.instance("data/pinnable-font.yaml");
	}
	private static int MAX_BG_BRIGHTNESS = 100;
	public boolean isInk(Color c, int x, int y) {
		int bright = (c.getRed() + c.getGreen() + c.getBlue()) / 3;
		return bright > MAX_BG_BRIGHTNESS;
	}

	public boolean doRemoveRules() { return false; }

	public void startTextScan(PixelBlock pb) {}

	public void setSpacePixelCount(int count) { m_spacePixelCount = count; }

	public int spacePixelCount() { return m_spacePixelCount; }

	public int textInset() { return 1;}

}
