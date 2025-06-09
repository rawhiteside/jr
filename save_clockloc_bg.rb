require 'java'
import javax.imageio.ImageIO
import org.foa.window.ClockLocWindow
import org.foa.PixelBlock

w = ClockLocWindow.new
pb = PixelBlock.new(w.textRectangle())


filename = "images/ClockLoc.png"
ImageIO.write(pb.buffered_image, 'png', java.io.File.new(filename))
