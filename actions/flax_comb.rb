require 'action'
require 'window'

class FlaxComb < Action
  def initialize
    super('Flax Comb', 'Buildings')
  end

  def setup(parent)
    gadgets = [
      {:type => :number, :label => 'Delay seconds', :name => 'delay'},
      {:type => :point, :label => 'Drag to comb window. (or a stack of them)', :name => 'w'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    delay = @vals['delay'].to_i
    loop do
      w = PinnableWindow.from_point(point_from_hash(@vals, 'w'))
      break unless w
      loop do
        # In case of "Really clean comb?"
        # Happens if we fail to read the comb text.
        # Won't be needed when the text read is perfect. 
        ConfirmationWindow.no
        sleep 0.1
        PopupWindow.dismiss
        w.refresh
        w.click_on('Continue') || w.click_on('Separate') || w.click_on('Clean')
        if w.read_text.include?('Repair')
          w.unpin
          break
        end
        sleep delay
      end
      sleep 1
    end
  end
end
Action.add_action(FlaxComb.new)

