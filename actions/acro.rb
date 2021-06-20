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
    
    x = 275
    y_base = 138
    y_off = 20
    move_count = w.count_moves
    return if move_count == 0

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
    puts 'acro helper'
    return AcroTextHelper.new
  end

  def count_moves
    pb = PixelBlock.new(rect)
    x = rect.width/2

    # The double-line separator below the moves to offer. 
    ymax = find_separator(pb, x)
    return 0 if ymax == -1
    
    
    border_color = Color.new(137, 83, 18).getRGB & 0xffffff
    border_count = 0
    5.upto(ymax) do |y|
      border_count += 1 if border_color == pb.get_pixel(x, y)
    end
    return border_count / 2
  end

  # Below the moves I have to offer is a double-line separator of a
  # constant color.  Find the first.
  def find_separator(pb, x)
    sep_color = Color.new(113, 76, 47).getRGB & 0xffffff
    0.upto(pb.rect.height - 1) do |y|
      return y if sep_color == pb.get_pixel(x, y)
    end
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
    puts "returning acro prefix"
    return 'acro'
  end
end

Action.add_action(AcroAction.new)
