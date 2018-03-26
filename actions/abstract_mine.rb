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

  # Main color(s) must be this high
  CTHRESH = 150
  # Diff between max and min must be this large
  CDIFF = 80
  # The paired colors must be this close
  CDIFF2 = 15
  def self.red?(r, g, b)
    r > CTHRESH && (r - g) > CDIFF && (r - b) > CDIFF && (g - b).abs < CDIFF2
  end

  def self.green?(r, g, b)
    g > CTHRESH && (g - r) > CDIFF && (g - b) > CDIFF && (r - b).abs < CDIFF2
  end

  def self.blue?(r, g, b)
    b > CTHRESH && (b - r) > CDIFF && (b - g) > CDIFF && (g - r).abs < CDIFF2
  end

  def self.cyan?(r, g, b)
    g > CTHRESH && b > CTHRESH && (g - r) > CDIFF && (g - b).abs < CDIFF2
  end

  def self.magenta?(r, g, b)
    r > CTHRESH && b > CTHRESH && (r - g) > CDIFF && (r - b).abs < CDIFF2
  end
    
  def self.yellow?(r, g, b)
    r > CTHRESH && g > CTHRESH && (r - b) > CDIFF && (r - g).abs < CDIFF2
  end

  def self.black?(r, g, b)
    cmax = [r, g, b].max
    cmin = [r, g, b].min
    return false if (cmax - cmin) > 10
    return false if cmax > 50 || cmax < 35
    return true
  end

  def self.grey?(r, g, b)
    max = [r, g, b].max
    min = [r, g, b].min
    min > 50 && max < 210 && (max - min) < 30
  end

  def self.color_symbol(color, gem_color = 'none', debug = false)
    r, g, b = color.getRed(), color.getGreen(), color.getBlue()

    METHOD_MAP.each_key do |k|
      if gem_color != k
        if self.send(METHOD_MAP[k], r, g, b)
          puts "Stone color #{k} from [#{r}, #{g}, #{b}]" if debug
          return k.to_sym
        end
      end
    end

    nil
  end

  def self.mine_color?(r, g, b)
    red?(r, g, b) || green?(r, g, b) || blue?(r, g, b) ||
      cyan?(r, g, b) ||yellow?(r, g, b) ||magenta?(r, g, b) ||
      grey?(r, g, b)
  end

end
