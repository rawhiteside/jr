package org.foa;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.awt.image.*;
import java.awt.event.*;


public class ImagePanel extends JPanel implements ActionListener {
    private BufferedImage m_image = null;
    private JLabel m_label = null;

    public ImagePanel(BufferedImage img) {
        super();
        m_image = img;
        setLayout(new BorderLayout());
        m_label = new JLabel();
        add(m_label, BorderLayout.CENTER);
        addButtons();
        setImage(img);
    }

    private void setImage(Image img) {
        m_label.setIcon(new ImageIcon(img));
        m_label.repaint();
    }

    private void addButtons() {
        Box box = Box.createVerticalBox();
        add(box, BorderLayout.WEST);
        box.add(makeButton("O"));
	box.add(Box.createVerticalStrut(20));
        box.add(makeButton("R"));
        box.add(makeButton("G"));
        box.add(makeButton("B"));
	box.add(Box.createVerticalStrut(20));
        box.add(makeButton("H"));
        box.add(makeButton("S"));
        box.add(makeButton("L"));
    }

    public void actionPerformed(ActionEvent e) {
        JButton b = (JButton) e.getSource();
        String cmd = b.getText();
        if(cmd.equals("O")) {
            setImage(m_image);
        } else {
            changeImage(cmd);
        }
    }

    private void changeImage(String cmd) {
        BufferedImage bi =
            new BufferedImage(m_image.getWidth(), m_image.getHeight(),
                              BufferedImage.TYPE_INT_RGB);   
        for(int x = 0; x < bi.getWidth(); x++) {
            for(int y = 0; y < bi.getHeight(); y++) {
                bi.setRGB(x, y, changePixel(m_image.getRGB(x, y), cmd));
	    }
	}
	setImage(bi);
    }

    private int changePixel(int pixel, String cmd) {

	Color c = new Color(pixel & 0xFFFFFF);
	float[] hsb;
	int val;
	
	switch (cmd) {
	case "R":
	    c = new Color(c.getRed(), 0, 0);
	    break;
	case "G":
	    c = new Color(0, c.getGreen(), 0);
	    break;
	case "B":
	    c = new Color(0, 0, c.getBlue());
	    break;
	case "H":
	    hsb = Color.RGBtoHSB(c.getRed(), c.getGreen(), c.getBlue(), null);
	    c = new Color(hsb[0], hsb[0], hsb[0]);
	    break;
	case "S":
	    hsb = Color.RGBtoHSB(c.getRed(), c.getGreen(), c.getBlue(), null);
	    c = new Color(hsb[1], hsb[1], hsb[1]);
	    break;
	case "L":
	    hsb = Color.RGBtoHSB(c.getRed(), c.getGreen(), c.getBlue(), null);
	    c = new Color(hsb[2], hsb[2], hsb[2]);
	    break;
	}
	return c.getRGB();
    }

    private JButton makeButton(String text) {
	JButton b = new JButton(text);
	b.addActionListener(this);
	return b;
    }

    public static void displayImage(BufferedImage bi, String title) {
	JFrame f = new JFrame(title);
	f.add(new ImagePanel(bi));
	f.pack();
	f.setVisible(true);
    }

    public static void main(String[] argv)  throws Exception {
	Rectangle rect = new Rectangle(100, 100, 300, 300);
	displayImage(new Robot().createScreenCapture(rect), "An Image");
    }
}
