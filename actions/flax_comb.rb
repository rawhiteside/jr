require 'action'
require 'window'

class FlaxComb < Action
  def initialize
    super('Flax Comb', 'Buildings')
  end


  def process(w)
    stat_wait('End')
    # Clean only if there's nothing else. 
    # Nil if nothing to click on.  The comb crashed.
    with_robot_lock do
      w.refresh
      w.click_on('Continue') || w.click_on('Separate') || w.click_on('Clean')
    end
  end
  
  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Drag to comb window (or stack of such).', :name => 'w'},
    ]
    @vals = UserIO.prompt(parent, @name, @name, gadgets)
  end

  def act
    loop do
      w = PinnableWindow.from_point(point_from_hash(@vals, 'w'))
      break unless w
      loop { break unless process(w) }
      p = PopupWindow.find
      p.dismiss if p
      w.unpin
    end
  end
end
Action.add_action(FlaxComb.new)

