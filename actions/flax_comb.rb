require 'action'
require 'window'

class FlaxComb < Action
  def initialize
    super('Flax Comb', 'Buildings')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Drag to comb window. (or a stack of them)', :name => 'w'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
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
        stat_wait :end

        w.refresh
        w.click_on('Continue') || w.click_on('Separate') || w.click_on('Clean')
        if w.read_text.include?('Repair')
          w.click_on('Repair/Load')
          sleep 0.2
          coords = [[690, 453], [690, 470], [690, 485]]
          dim = ARobot.sharedInstance.screen_size
          coords.each do |xy|
            checkForPause
            sleep 0.3
            lclick_at(xy[0], xy[1]) if PopupWindow.find
            sleep 0.3
            HowMuch.max
            sleep 0.3
          end
        end
        sleep 1
      end
      sleep 1
    end
  end
end
Action.add_action(FlaxComb.new)

