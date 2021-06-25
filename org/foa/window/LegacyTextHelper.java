package org.foa.window;
import java.awt.Color;
import java.util.*;
import java.io.*;

import org.yaml.snakeyaml.Yaml;

import org.foa.text.*;
import org.foa.PixelBlock;


public class LegacyTextHelper implements ITextHelper{
	private static Map s_bgMap = null;
	static {
		try {
			FileReader r = new FileReader("data/chat-bg.yaml");
			Yaml yaml = new Yaml();
			s_bgMap = (Map) yaml.load(r);
			r.close();
		} catch(Exception e) {
			System.out.println("Exception: in LegacyTextHelpere" + e.toString());
			e.printStackTrace();
		}
	}


	public LegacyTextHelper() {
	}

	private static int RMIN = 0xb9; // 185
	private static int GMIN = 0xaa; // 170
	private static int BMIN = 0x81; // 129
	private int m_spacePixelCount = 4;
	// ITextHelper methods.

	public void startTextScan(PixelBlock pb) {}

	public AFont getFontMap() { return AFont.instance("data/font.yaml"); }

	public boolean isInk(Color c, int x, int y) {
		//return s_bgMap.get(c.getRGB() & 0xFFFFFF) == null;
		return c.getRed() < RMIN || c.getGreen() < GMIN || c.getBlue() < BMIN;
	}

	public boolean doRemoveRules() { return true; }

	public void setSpacePixelCount(int count) { m_spacePixelCount = count; }

	public int spacePixelCount() { return m_spacePixelCount; }

	public String imagePrefix() { return "legacy"; }

}
