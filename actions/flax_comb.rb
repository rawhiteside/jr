require 'action'
require 'window'

class FlaxComb < Action
  def initialize
    super('Flax Comb', 'Buildings')
  end

  def setup(parent)
    gadgets = [
      {:type => :number, :label => 'Delay seconds', :name => 'delay'},
      {:type => :point, :label => 'Drag to comb window.', :name => 'w'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    delay = @vals['delay'].to_i
    w = PinnableWindow.from_point(point_from_hash(@vals, 'w'))
    loop do
      break unless w
      w.default_refresh_loc = 'lc'
      w.refresh
      w.click_on('Repair') || w.click_on('Continue') || w.click_on('Separate') || w.click_on('Clean')
      sleep delay
    end
  end
end
Action.add_action(FlaxComb.new)

