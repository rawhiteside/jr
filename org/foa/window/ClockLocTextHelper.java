package org.foa.window;
import org.foa.text.*;
import java.awt.Color;
import org.foa.PixelBlock;


public class ClockLocTextHelper implements ITextHelper{

	private static String[] s_bgImageNames = {
		"ClockLoc-green.png",
		"ClockLoc-orange.png",
		"ClockLoc-yellow.png",
		"ClockLoc-teal.png",
	};
	private static PixelBlock[] s_images = new PixelBlock[s_bgImageNames.length];
	static {
		for(int i = 0; i < s_bgImageNames.length; i++) {
			s_images[i] = PixelBlock.loadImage("images/" + s_bgImageNames[i]);
		}
	}

	private PixelBlock m_currentBg = null;

	public ClockLocTextHelper() { }

	public void startTextScan(PixelBlock pb) {
		for(int i = 0; i < s_images.length; i++) {
			if (pb.getPixel(0, 0) == s_images[i].getPixel(0,0)) {
				m_currentBg = s_images[i];
				return;
			}
		}
		System.out.println("Cound not find background.");
		m_currentBg = null;
	}

	public AFont getFontMap() { return AFont.instance("data/clockloc-font.yaml"); }

	public boolean isInk(Color c, int x, int y) {
		return !c.equals(m_currentBg.getColor(x, y));
	}

	public boolean doRemoveRules() { return false; }

	private int m_spacePixelCount = 6;
	public void setSpacePixelCount(int count) { m_spacePixelCount = count; }

	public int spacePixelCount() { return m_spacePixelCount; }

	public String imagePrefix() { return "clockloc"; }



}
