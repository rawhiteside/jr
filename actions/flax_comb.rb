require 'action'
require 'window'

class FlaxComb < Action
  def initialize
    super('Flax Comb', 'Buildings')
  end


  def process(w)
    w.refresh
    stat_wait('End')
    w.refresh
    next if w.click_on('Continue')
    next if w.click_on('Separate')
    # This only if there's nothing else. 
    w.click_on('Clean')
  end
  
  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Drag to comb window', :name => 'w'},
    ]
    @vals = UserIO.prompt(parent, @name, @name, gadgets)
  end

  def act
    w = PinnableWindow.from_point(point_from_hash(@vals, 'w'))
    unless w
      UserIO.error('No window found')
      return
    end
    loop { process(w) }

  end
end
Action.add_action(FlaxComb.new)

