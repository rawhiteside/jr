require 'action'
require 'window'

class PyramidPushStack < Action
  def initialize
    super('Pyramid push', 'Misc')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Drag to stack of Rolling blocks', :name => 'win'},
      {:type => :combo, :label => 'Which direction?', :name => 'direction',
       :vals => ['North', 'South', 'East', 'West'],
      },
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    dir = @vals['direction']
    while win = PinnableWindow.from_point(point_from_hash(@vals, 'win'))
      push(win, dir)
    end
  end

  def push(win, direction)
    loop do
      win.refresh
      text = win.read_text
      if text && text.include?(direction)
        stat_wait :end
        win.click_on("Push this block #{direction}")
        sleep 1.0
      else
        win.unpin
        sleep 1.0
        break
      end
    end
  end
end

Action.add_action(PyramidPushStack.new)


class PyramidDigStack < Action
  def initialize
    super('Pyramid dig', 'Misc')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Drag to stack of Excavations', :name => 'win'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    while win = PinnableWindow.from_point(point_from_hash(@vals, 'win'))
      dig(win)
    end
  end

  def dig(win)
    loop do
      win.refresh
      text = win.read_text
      if text
        stat_wait :end
        win.refresh
        if win.click_on("Dig")
          win.refresh
          win.click_on("Slide")
        else
          break
        end
        sleep 1.0
      else
        break
      end
    end
    win.unpin
    sleep 0.1
  end

end

Action.add_action(PyramidDigStack.new)
