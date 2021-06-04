import java.awt.Rectangle

class Stats
  @@stat_image_map = {}
  {'End' => 'images/Endurance.png',
   'Foc' => 'images/Focus.png',
   'Per' => 'images/Perception.png',
  }.each {|k, v| @@stat_image_map[k] = PixelBlock.load_image(v)}
  end
  centerx = ARobot.shared_instance.screen_size.width/2
  @@stat_rect = Rectangle.new(centerx - 150, 100, 300, 100)
  puts @@stat_rect

  def self.stat_ok?(stat)
    image = @@stat_image_map[stat]
    pb = PixelBlock.new(@@stat_rect)
    return pb.find_template_exact(image).nil?
  end
end
