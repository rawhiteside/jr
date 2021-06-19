package org.foa.window;
import org.foa.text.*;
import java.awt.Color;
import org.foa.PixelBlock;


public class LegacyTextHelper implements ITextHelper{

	public LegacyTextHelper() {
	}

	private static int RMIN = 0xb9;
	private static int GMIN = 0xb4;
	private static int BMIN = 0x81;
	private int m_spacePixelCount = 4;
	// ITextHelper methods.

	public void startTextScan(PixelBlock pb) {}

	public AFont getFontMap() { return AFont.instance("data/font.yaml"); }

	public boolean isInk(Color c, int x, int y) {
		return c.getRed() < RMIN || c.getGreen() < GMIN || c.getBlue() < BMIN;
	}

	public boolean doRemoveRules() { return true; }

	public void setSpacePixelCount(int count) { m_spacePixelCount = count; }

	public int spacePixelCount() { return m_spacePixelCount; }

	public String imagePrefix() { return "legacy"; }

}
