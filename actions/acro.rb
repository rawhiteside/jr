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
    w.drag_to(50, 50) unless w.rect.x == 50
    
    skip_these = @vals['skip-these']
    skip = []
    skip_these.split(',').each {|s| skip << s.strip.to_i}
    
    x = 275
    y_base = 138
    y_off = 20
    move_count = count_moves(w)
    loop do
      move_count.times do |i|
        next if skip.include?(i)
        stat_wait :acro
        lclick_at x, y_base + i * y_off
        sleep 3
      end
    end
  end

  def count_moves(w)
    rect = w.rect
    dim = screen_size
    border_color = Color.new(137, 83, 18).getRGB & 0xffffff
    pb = PixelBlock.full_screen
    x = 275
    y = 75
    border_count = 0
    y.upto(rect.y + rect.height - 1) do |y|
      border_count += 1 if pb.getPixel(x, y) == border_color
    end
    return border_count/2
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
    InventoryTextHelper.new
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
Action.add_action(AcroAction.new)
