import java.awt.*;
import java.awt.geom.*;
import java.awt.image.BufferedImage;
import javax.swing.*;
import javax.swing.event.*;
  
public class PanAndZoom implements ChangeListener {
    BufferedImage image;
    JLabel label;
  
    public void stateChanged(ChangeEvent e) {
        int value = ((JSlider)e.getSource()).getValue();
        double scale = value/100.0;
        BufferedImage scaled = getScaledImage(scale);
        label.setIcon(new ImageIcon(scaled));
        label.revalidate();  // signal scrollpane
    }
  
    private BufferedImage getScaledImage(double scale) {
        int w = (int)(scale*image.getWidth());
        int h = (int)(scale*image.getHeight());
        BufferedImage bi = new BufferedImage(w, h, image.getType());
        Graphics2D g2 = bi.createGraphics();
        g2.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
                            RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        AffineTransform at = AffineTransform.getScaleInstance(scale, scale);
        g2.drawRenderedImage(image, at);
        g2.dispose();
        return bi;
    }
  
    private JLabel getContent() {
        createAnImage();
        label = new JLabel(new ImageIcon(image));
        label.setHorizontalAlignment(JLabel.CENTER);
        return label;
    }
  
    private void createAnImage() {
        int w = 500;
        int h = 500;
        int type = BufferedImage.TYPE_INT_RGB; // many options
        image = new BufferedImage(w, h, type);
        Graphics2D g2 = image.createGraphics();
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                            RenderingHints.VALUE_ANTIALIAS_ON);
        g2.setRenderingHint(RenderingHints.KEY_STROKE_CONTROL,
                            RenderingHints.VALUE_STROKE_PURE);
        g2.setPaint(new Color(240,200,200));
        g2.fillRect(0,0,w,h);
        g2.setPaint(Color.blue);
        g2.draw(new Rectangle2D.Double(0,0,10,10));

        g2.dispose();
    }
  
    private JSlider getControl() {
        JSlider slider = new JSlider(JSlider.HORIZONTAL, 50, 200, 100);
        slider.setMajorTickSpacing(50);
        slider.setMinorTickSpacing(10);
        slider.setPaintTicks(true);
        slider.setPaintLabels(true);
        slider.addChangeListener(this);
        return slider;        
    }
  
    public static void main(String[] args) {
        PanAndZoom app = new PanAndZoom();
        JFrame f = new JFrame();
        f.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        f.getContentPane().add(new JScrollPane(app.getContent()));
        f.getContentPane().add(app.getControl(), "Last");
        f.setSize(400, 400);
        f.setLocation(200,200);
        f.setVisible(true);
    }
}
