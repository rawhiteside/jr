require 'action'

class AbstractMine < Action
  
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
  
  def self.color_symbol(color, gem_color = 'none', debug = false)
    r, g, b = color.getRed(), color.getGreen(), color.getBlue()
    hsb = Color.RGBtoHSB(r, g, b, nil)
    hue = hsb[0] * 359
    sat = hsb[1] * 255
    bright = hsb[2] * 255
    
    METHOD_MAP.each_key do |k|
      if gem_color != k
        if self.send(METHOD_MAP[k], hue, sat, bright)
          # puts "Stone color #{k} from [#{hue}, #{r}, #{g}, #{b} ]" if debug
          return k.to_sym
        end
      end
    end
    
    nil
  end
end
