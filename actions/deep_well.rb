require 'action'
require 'window'

# Don't think this will get used, but having the DeepWellWindow is
# handy, and this can test it.
class DeepWellAction < Action
  def initialize
    super('Deep Well', 'Buildings')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :name => 'well', :label => 'Pinned deep well'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    pinnable = PinnableWindow.from_point(point_from_hash(@vals, 'well'))
    well_window = DeepWellWindow.new(pinnable)
    loop do
      rv = well_window.tend_once
      sleep 5
    end
  end
end
Action.add_action(DeepWellAction.new)

class DeepWellWindow < PinnableWindow
  include Utils

  def initialize(pinnable)
    super(pinnable.rect.dup)
  end

  # Do something with the well. Return values are:
  #
  # wait_for_end: Whether to wait for a red END to change.
  #
  # :ok -- Successfully wound, or red :end and no-wait
  # :no_wait -- Stat was red and no-waiy specified
  # :max_tension -- No wind.  Well was at max tension.
  # :broken -- No wind.  Well needs repair
  def tend_once(wait_for_end = true)
    refresh
    text = read_text
    return :broken if text =~ /Repair/
    match = Regexp.new('Spring Tension is +([0-9 ]+)').match(text)
    tension = match[1].tr(' ','').to_i
    return :max_tension if tension >= 100
    if !stat_ok? :end
      return :no_wait unless wait_for_end
    end

    stat_wait :end
    return :ok if click_on('Wind')
    puts "DeepWellWindow: this should not happen."
    return :ok
  end
end
