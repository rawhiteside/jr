require 'java'
require 'mesh-canon'

java_import javax.imageio.ImageIO
java_import java.awt.Color
java_import java.awt.BasicStroke



def map_gen
  puts "lkj"  
  bi = ImageIO.read(java.io.File.new("meshmap/AtitdFullMap.png"))
  puts "lkj"
  g = bi.create_graphics
  g.set_color(Color.cyan)
  g.set_stroke(BasicStroke.new(2))
  g.draw_line(4000, 4000, 5000, 5000)

  c = CanonicalLineSegList.load
  c.to_a.each do |xy_t|
    xy = [to_image_coords(xy_t[0]), to_image_coords(xy_t[1])]
    g.draw_line(xy[0][0], xy[0][1], xy[1][0], xy[1][1])
    g.fill_oval(xy[0][0]-2, xy[0][1]-2, 5, 5)
    g.fill_oval(xy[1][0]-2, xy[1][1]-2, 5, 5)
  end

  file = "mesh-destinations.yaml"
  name_map = {}
  name_map = YAML.load_file(file) if File.exist?(file)
  g.set_color(Color.pink)
  name_map.each do |k,v|
    xy = to_image_coords(v)
    g.fill_oval(xy[0], xy[1], 20, 20)
  end
  
  ImageIO.write(bi, 'png', java.io.File.new("meshmap/AnnotatedMap.png"))
  puts "lkj"
end

def to_image_coords(xy)
    [xy[0] + (2048 + 1024), -xy[1] + 8192]
end

map_gen

