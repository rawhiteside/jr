require 'action'
require 'walker'

class CasualSlate < Action
  def initialize
    super('Casual Slate', 'Gather')
  end

  def act
    loop do
      if Icons.click_on(:slate)
	sleep_sec 0.1
        HowMuch.cancel_if_present
      else
	Thread.pass
      end
    end
  end
end

class Slate < Action
  def initialize
    super('Slate', 'Gather')
    @threads = []
    @walker = Walker.new
  end

  def start_slate_watcher
    @threads << ControllableThread.new { CasualSlate.new.act }
  end

  def persistence_name
    'Slate'
  end
  def setup(parent)
    gadgets = 
      [
        :type => :world_path, :label => "Slate path", :name => "coords",
      ]
    vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)

    return nil unless vals

    @loop = WorldLocUtils.parse_world_path(vals['coords'])
    true
  end

  def act
    ControllableThread.check_for_pause
    @walker.walk_to(@loop[0])
    start_slate_watcher
    @walker.walk_loop(@loop, 9999)
  end

  def stop
    @threads.each {|t| t.kill}
    super
  end
end

Action.add_action(Slate.new)
Action.add_action(CasualSlate.new)
