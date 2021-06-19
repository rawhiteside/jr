package org.foa.window;
import org.foa.text.*;
import java.awt.Color;
import org.foa.PixelBlock;

public class InventoryTextHelper implements ITextHelper{

	public InventoryTextHelper() { }


	public void startTextScan(PixelBlock pb) {}

	public AFont getFontMap() { return AFont.instance("data/font.yaml"); }

	public boolean isInk(Color c, int x, int y) {
		return (c.getRed() >= 85 || c.getGreen() >= 85 || c.getBlue() >= 85);
	}

	public boolean doRemoveRules() { return true; }

	private int m_spacePixelCount = 4;
	public void setSpacePixelCount(int count) { m_spacePixelCount = count; }
	public int spacePixelCount() { return m_spacePixelCount; }

	public String imagePrefix() { return "inventory"; }
}
