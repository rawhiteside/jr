require 'action'

class AbstractMine < Action
  # 
  # Mine, then identify the new stones in the scene.
  # Returned as globs, which are Point[][].
  def mine_get_globs(w, stone_count)
    wait_for_mine(w)
    w.click_on('Stop Working', 'tc')
    sleep(5.0)
    
    @empty_image = full_screen_capture
    w.click_on('Work this Mine', 'tc')
    sleep(10.0)

    @stones_image = full_screen_capture
    diff_image = ImageUtils.xor(@empty_image, @stones_image)
    # 
    # Clear mine window, since they changed.
    zero_menu_rect(diff_image, w.rect)

    globs = get_globs(diff_image)
    globs = globs.sort { |g1, g2| g2.size <=> g1.size }
    return globs.slice(0, stone_count)
  end

  # We have to copy the Java arrays into Ruby arrays, so they get the
  # expected methods.
  def get_globs(pb_xor)
    got = Globifier.globify(pb_xor)
    globs = []
    got.each { |g| globs << g.to_a }
    globs
  end

  # Wait until the mine can be worked again.
  def wait_for_mine(w)
    loop do
      w.refresh
      break unless w.read_text =~ /This mine can be/
      sleep(1)
    end
  end
  
  # Zero out the pixels in the provided rectangle.
  def zero_menu_rect(pb, rect)
    rect.x.upto(rect.x + rect.width) do |x|
      rect.y.upto(rect.y + rect.height) do |y|
        pb.set_pixel(x, y, 0)
      end
    end
  end
  
end

class Clr
  
  METHOD_MAP = {
    'red' => :red?,
    'green' => :green?,
    'blue' => :blue?,
    'cyan' => :cyan?,
    'magenta' => :magenta?,
    'yellow' => :yellow?,
  }
  
  def self.red?(hue, sat, bright)
    return (5..8).cover?(hue) && sat > 100 && bright > 100
  end
  
  def self.green?(hue, sat, bright)
    return (110..114).cover?(hue) && sat > 100
  end
  
  def self.blue?(hue, sat, bright)
    return (243..249).cover?(hue) && sat > 100
  end
  
  def self.cyan?(hue, sat, bright)
    return (172..175).cover?(hue) && sat > 100
  end
  
  def self.magenta?(hue, sat, bright)
    return (291..295).cover?(hue) && sat > 100
  end
  
  def self.yellow?(hue, sat, bright)
    return (54..60).cover?(hue) && sat > 100
  end
  
  def self.color_symbol(color)
    r, g, b = color.getRed(), color.getGreen(), color.getBlue()
    hsb = Color.RGBtoHSB(r, g, b, nil)
    hue = hsb[0] * 359
    sat = hsb[1] * 255
    bright = hsb[2] * 255
    
    METHOD_MAP.each_key do |k|
      if self.send(METHOD_MAP[k], hue, sat, bright)
        return k.to_sym
      end
    end
    
    nil
  end
end


class OreStone
  attr_accessor :points, :min_point, :max_point, :centroid
  attr_accessor :color_symbol

  def initialize(points)
    @points = points
    xmin = ymin = 99999999
    xmax = ymax = 0
    xsum = ysum = 0
    points.each do |p|
      x, y = p.x, p.y
      xmin = x if x < xmin 
      ymin = y if y < ymin 

      xmax = x if x > xmax 
      ymax = y if y > ymax

      xsum += x
      ysum += y
    end

    @min_point = Point.new(xmin, ymin)
    @max_point = Point.new(xmax, ymax)
    @centroid = Point.new(xsum / points.size, ysum / points.size)
  end

  def x
    @centroid.x
  end
  def y
    @centroid.y
  end

  def to_s
    "stone: size=#{@points.size}, centroid=[#{@centroid.x}, #{@centroid.y}], color=#{@color_symbol}, rectangle: #{rectangle.toString()}"
  end

  def rectangle
    Rectangle.new(@min_point.x, @min_point.y,
                  @max_point.x - @min_point.x + 1, 
                  @max_point.y - @min_point.y + 1)
  end
end

