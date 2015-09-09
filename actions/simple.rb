require 'action'

class IntervalTab < Action
  def initialize
    super("Inverval tabs", "Misc")
  end

  def setup(parent)
    @delay = get_delay_secs(parent)
  end

  def act
    return unless @delay > 0

    loop do
      sleep_sec @delay
      ControllableThread.check_for_pause
      send_vk(VK_TAB)
    end
  end
  
  def get_delay_secs(parent)
    c = [{:type => :text, :label => 'Secs between tabs', :name => 'interval'}]
    vals = UserIO.prompt(parent, 'Interval tab', 'Interval tabs', c)
    return nil unless vals
    return vals['interval'].to_f
  end
end

Action.add_action(IntervalTab.new)
