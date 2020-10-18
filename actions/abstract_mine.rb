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
