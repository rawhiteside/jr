require 'java'
java_import org.foa.robot.ARobot
java_import java.awt.Rectangle
java_import java.awt.Color

def dump_rect(rect) 
  img = ARobot.sharedInstance.create_screen_capture(rect)
  colors = {}
  rect.height.times do |y|
    rect.width.times do |x|
      c = Color.new(img.getRGB(x, y))
      rgb = [c.get_red, c.get_green, c.get_blue]
      colors[rgb] = 1
    end
  end
  puts "Got it"
  puts " input: #{rect.height * rect.width}"
  puts " output: #{colors.size}"
  vec = colors.keys
  label = ["r", "g", "b", "ink", "mn", "mx", "bright", "rng"]
  vec.each do |k|
    r, g, b = k[0], k[1], k[2]
    ink = ink_spot_test(r, g, b)
    mn = k.min
    mx = k.max
    bright = r + g + b
    rng = mx - mn
    k.concat([ink, mn, mx, bright, rng])
  end
  
  
  puts "#{label}"
  vec.each do |k| puts "#{k}" end

end

def ink_spot_test(r, g, b)
  rmin = 0xca
  gmin = 0xb4
  bmin = 0x81
  r < rmin || b < bmin || g < gmin
end


rect = Rectangle.new(5, 5, 10, 5)
dump_rect(rect)
