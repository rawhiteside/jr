require 'action'

class WoodPlane < Action
  def initialize
    super('Wood planes', 'Buildings')
    @threads = []
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :name => 'stack', :label => 'Drag to the stack of menus'},
      {:type => :combo, :name => 'type', :label => 'Building', :vals => ['Wood plane', 'Carpentry shop']},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end
  
  def find_windows
    x = @vals['stack.x'].to_i
    y = @vals['stack.y'].to_i
    tiler = Tiler.new(2, 90, 0)
    tiler.y_offset = 10
    tiler.min_width = 386
    @windows = tiler.tile_stack(x, y)
  end
  
  def plane(w)
    is_woodplane = (@vals['type'] == 'Wood plane')
    stat_wait :end
    w.refresh
    if is_woodplane
      w.refresh if (w.click_on('Repair') || w.click_on('Install'))
    end
    if w.click_on('Plane')
      if is_woodplane
        w.refresh
        if w.click_on('Repair')
          w.refresh
          w.click_on('Plane')
        end
      end
    end
  end

  def act
    find_windows
    return unless @windows && @windows.size > 0

    loop { @windows.each {|w| plane(w)}}
  end

end

Action.add_action(WoodPlane.new)
