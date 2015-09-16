require 'action'

class MineIron < Action

  def initialize
    super("Mine Iron", "Buildings")
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Drag onto the pinned Mine',
	:name => 'mine'},
      {:type => :point, :label => 'Drag to UL point of ore stone field',
	:name => 'ul'},
      {:type => :point, :label => 'Drag to LR point of ore stone field',
	:name => 'lr'},
    ]
    @vals = UserIO.prompt(parent, 'mine-iron', 'mine-iron', gadgets)
  end

  def act
    # Get the mine menu
    pt_menu = point_from_hash(@vals, 'mine')
    mine = PinnableWindow.from_point(pt_menu)
    x = @vals['ul.x'].to_i
    y = @vals['ul.y'].to_i
    width = @vals['lr.x'].to_i - x
    height = @vals['lr.y'].to_i - y
    
    # Stop working, and take a shot of the clear ore field
    mine.refresh
    mine.click_on('Stop')
    sleep 0.5
    pb_empty = screen_rectangle(x, y, width, height)

    # Work the mine, and take another shot
    mine.click_on('Work this')
    sleep 5
    pb_full = screen_rectangle(x, y, width, height)

    scan(pb_empty, pb_full)
    

  end


  def scan(pbe, pbf)
    
  end
end

Action.add_action(MineIron.new)
