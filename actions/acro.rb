require 'action'
require 'utils'

class AcroAction < Action
  def initialize
    super('Acro', 'Misc')
  end
  
  def setup(parent)
    gadgets = [
      {:type => :text, :label => 'Which moves to skip? (zero-based)', :name => 'skip-these'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    # Find teh acro window
    w = AcroWindow.find
    # Read text, just to get the screenshot on failure.
    w.read_text
    w.drag_to(50, 50) unless w.rect.x == 50
    
    skip_these = @vals['skip-these']
    skip = []
    skip_these.split(',').each {|s| skip << s.strip.to_i}
    
    move_count = w.count_moves
    if move_count == 0
      puts "Acro: No moves to offer."
      return
    end

    x = 275
    y_base = 138
    y_off = 20
    loop do
      move_count.times do |i|
        next if skip.include?(i)
        stat_wait :acro
        lclick_at x, y_base + i * y_off
        sleep 3
      end
    end
  end

end

class AcroWindow < AWindow
  # Look at the center, then over on the left. 
  def self.find
    dim = ARobot.shared_instance.screen_size
    pt = Point.new(dim.width/2, 220)
    w =  AcroWindow.from_point(pt)
    return w if w 

    pt = Point.new(75, 75)
    return AcroWindow.from_point(pt)
  end

  def initialize(rect)
    super(rect)
  end

  def getTextHelper()
    return AcroTextHelper.new
  end

  def count_moves
    pb = PixelBlock.new(rect)
    x = rect.width/2

    # The double-line separator below the moves to offer. 
    ymax = find_separator(pb, x)
    puts "no separator" if ymax == -1
    return 0 if ymax == -1

    border_color = Color.new(137, 83, 18)
    border_count = 0
    5.upto(ymax) do |y|
      border_count += 1 if ImageUtils.color_diff(border_color,pb.get_color(x, y)) < 2
    end
    return border_count / 2
  end

  # Below the moves I have to offer is a double-line separator of a
  # constant color.  Find the first.
  def find_separator(pb, x)
    sep_color = Color.new(113, 76, 47)
    (125 - pb.rect.y).upto(pb.rect.height - 1) do |y|
      return y if ImageUtils.color_diff(sep_color, pb.get_color(x, y)) < 2
      # return y if sep_color == pb.get_pixel(x, y)
    end
    puts "Acro: No separator found."
    return -1
  end

  def textRectangle
    r = rect
    r.width -= 23
    return r
  end

  def getTextHelper()
    AcroTextHelper.new
  end

  def self.from_point(pt)
    rect = LegacyWindowGeom.new.rect_from_point(pt)
    if rect
      return AcroWindow.new(rect)
    else
      return nil
    end
  end
  
end

class AcroTextHelper < InventoryTextHelper
  def imagePrefix
    'acro'
  end
end

Action.add_action(AcroAction.new)
