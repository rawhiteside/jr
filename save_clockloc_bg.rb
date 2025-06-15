require 'java'
java_import javax.imageio.ImageIO
java_import org.foa.window.ClockLocWindow
java_import org.foa.PixelBlock

w = ClockLocWindow.new
pb = PixelBlock.new(w.textRectangle())


filename = "images/ClockLoc.png"
ImageIO.write(pb.buffered_image, 'png', java.io.File.new(filename))
