import java.awt.Rectangle

class Stats
  @@stat_image_map = {}
  {'End' => 'images/Endurance.png',
   'Foc' => 'images/Focus.png',
   'Per' => 'images/Perception.png',
  }.each {|k, v| @@stat_image_map[k] = PixelBlock.load_image(v)}

  centerx = ARobot.shared_instance.screen_size.width/2
  @@stat_rect = Rectangle.new(centerx - 150, 100, 300, 100)

  def self.stat_ok?(stat)
    image = @@stat_image_map[stat]
    pb = PixelBlock.new(@@stat_rect)
    rv = pb.find_template_exact(image).nil?
    puts "stat_ok?(#{stat}) -> #{rv}"
    return rv
  end
end
