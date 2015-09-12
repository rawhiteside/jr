require 'action'
require 'walker'

class CasualSlate < Action
  def initialize
    super('Casual Slate', 'Gather')
  end

  def act
    pixel = 0xFCFCFA
    xy = [164, 50]
    loop do
      if pixel == get_pixel(*xy)
	rclick_at_restore(xy[0], xy[1])
	sleep_sec 0.1
      else
	sleep_sec 0.01
	# Thread.pass
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

  def setup(parent)
    gadgets = 
      [
        :type => :world_path, :label => "Slate path", :name => "coords",
      ]
    vals = UserIO.prompt(parent, "Slate", "Slate", gadgets)

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
