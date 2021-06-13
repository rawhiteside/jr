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

	private static final String ORIGINAL  = "Original";
	private static final String RED = "Red";
	private static final String GREEN = "Green";
	private static final String BLUE = "Blue";
	private static final String HUE = "Hue";
	private static final String SAT = "Sat";
	private static final String LUM = "Lum";
	private static final String EDGES = "Edges";
	private static final String BW = "BW";

	private void addButtons() {
		Box box = Box.createVerticalBox();
		add(box, BorderLayout.WEST);
		box.add(makeButton(ORIGINAL));
		box.add(Box.createVerticalStrut(20));
		box.add(makeButton(RED));
		box.add(makeButton(GREEN));
		box.add(makeButton(BLUE));
		box.add(Box.createVerticalStrut(20));
		box.add(makeButton(HUE));
		box.add(makeButton(SAT));
		box.add(makeButton(LUM));
		box.add(makeButton(BW));
	}

	public void actionPerformed(ActionEvent e) {
		JButton b = (JButton) e.getSource();
		String cmd = b.getText();
		if(cmd.equals(ORIGINAL)) {
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
		case RED:
			c = new Color(c.getRed(), c.getRed(), c.getRed());
			break;
		case GREEN:
			c = new Color(c.getGreen(), c.getGreen(), c.getGreen());
			break;
		case BLUE:
			c = new Color(c.getBlue(), c.getBlue(), c.getBlue());
			break;
		case HUE:
			hsb = Color.RGBtoHSB(c.getRed(), c.getGreen(), c.getBlue(), null);
			c = new Color(hsb[0], hsb[0], hsb[0]);
			break;
		case SAT:
			hsb = Color.RGBtoHSB(c.getRed(), c.getGreen(), c.getBlue(), null);
			c = new Color(hsb[1], hsb[1], hsb[1]);
			break;
		case LUM:
			hsb = Color.RGBtoHSB(c.getRed(), c.getGreen(), c.getBlue(), null);
			c = new Color(hsb[2], hsb[2], hsb[2]);
			break;
		case BW:
			if((pixel & 0xFFFFFF) == 0) {
				return 0;
			} else {
				return 0xFFFFFF;
			}
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
