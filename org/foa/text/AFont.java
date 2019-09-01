package org.foa.text;

import java.util.*;
import java.io.FileReader;
import java.io.FileWriter;

import org.yaml.snakeyaml.Yaml;


public class AFont {
    private static AFont s_instance;
    private Map m_map;
    private String UNKNOWN_GLYPH = "?";
    private String FONT_FILE = "font.yaml";

    public AFont() throws Exception {

	FileReader r = new FileReader(FONT_FILE);
	Yaml yaml = new Yaml();
	try { m_map = (Map) yaml.load(r); }
	catch(Exception e) {
	    System.out.println("Exception: in AFont" + e.toString());
	    e.printStackTrace();
	    throw e;
	}
	finally { r.close(); }
    }

    public static AFont instance() {
	if(s_instance == null) {
	    try { s_instance = new AFont(); }
	    catch(Exception e){}
	}
	return s_instance;
    }

    public void save() {
	try {
	    FileWriter w = new FileWriter(FONT_FILE);
	    Yaml yaml = new Yaml();
	    try { yaml.dump(m_map, w); }
	    finally { w.close(); }
	} catch (Exception e) {
	    System.out.println(e.toString());
	}
    }

    public void add(String[] rows, String str) {
	ArrayList l = new ArrayList(Arrays.asList(rows));
	if (isDuplicate(l, str)) {
	    return;
	}
	m_map.put(l, str);
	save();
    }

    public String textFor(String[] rows) {
		ArrayList l = new ArrayList(Arrays.asList(rows));
		
		String val = (String) m_map.get(l);
		return val == null ? UNKNOWN_GLYPH : val;
    }

    private boolean isDuplicate(ArrayList rows, String str) {
	String val = (String) m_map.get(rows);
	if (val != null) {
	    if (!str.equals(val)) {
		System.out.println("Inconsistent entries.  Pixels:");
		System.out.println(rows.toString());
		System.out.println("Old str: " + val + ", New str: " + str);
		return true;
	    }
	}
	return false;
    }
}
