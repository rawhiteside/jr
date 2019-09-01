require 'action'

class WoodPlane < Action
  def initialize
    super('Wood planes', 'Buildings')
    @threads = []
  end

  def persistence_name
    'Wood Planes'
  end

  def setup(parent)
    gadgets = [
      { :type => :point, :name => 'stack', :label => 'Drag to the stack of menus' }
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end
  
  def find_windows
    x = @vals['stack.x'].to_i
    y = @vals['stack.y'].to_i
    tiler = Tiler.new(2, 70, 0)
    tiler.y_offset = 10
    tiler.min_width = 386
    @windows = tiler.tile_stack(x, y)
  end
  
  def plane(w)
    loop do
      w.refresh
      w.refresh if w.click_on('Repair')
      if w.click_on('Plane')
        w.refresh
        if w.click_on('Repair')
          w.refresh
          w.click_on('Plane')
        end
        break
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
