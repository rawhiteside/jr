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
    @vals = UserIO.prompt(parent, 'block', 'Block', gadgets)
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
        stat_wait('End')
        win.click_on("Push this block #{direction}")
        sleep_sec 1.0
      else
        win.unpin
        break
      end
    end
  end
end

Action.add_action(PyramidPushStack.new)
