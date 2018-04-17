require 'action'
require 'window'

class FlaxComb < Action
  def initialize
    super('Flax Comb', 'Buildings')
  end


  def process(w, max_clean)
      clean_count = 0
      loop do 
        did_something = nil
        stat_wait('End')
        # Clean only if there's nothing else. 
        # Nil if nothing to click on.  The comb crashed.
        rv = nil
        with_robot_lock do
          w.refresh
          did_something = nil
          if w.click_on('Continue') || w.click_on('Separate')
            did_something = true
          else
            break if clean_count >= max_clean
            if w.click_on('Clean')
              did_something = true
              clean_count += 1
            end
          end
          break unless did_something
          sleep_sec(0.1)
          w.refresh
          sleep_sec(0.1)
        end
        break unless did_something
      end
  end
  
  def setup(parent)
    gadgets = [
      {:type => :number, :label => 'Max count for Clean.', :name => 'count'},
      {:type => :point, :label => 'Drag to comb window (or stack of such).', :name => 'w'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    clean_count = 0
    max_clean = @vals['count'].to_i
    # Process the stack of windows.
    loop do
      w = PinnableWindow.from_point(point_from_hash(@vals, 'w'))
      break unless w
      w.default_refresh_loc = 'lc'
      process(w, max_clean)
      # 
      # Dismiss the box telling me the comb died. 
      p = PopupWindow.find
      p.dismiss if p
      # 
      # Lose the done comb.
      w.unpin
    end
  end
end
Action.add_action(FlaxComb.new)

