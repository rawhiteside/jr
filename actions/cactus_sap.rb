require 'action'
require 'walker'

class CactusRun < Action
  def initialize
    super('Cactus run', 'Gather')
  end

  def setup(parent)
    gadgets = [
      {:type => :world_path, :label => 'Path to walk.', :name => 'path', :aux => ['Collect', 'Stash']},
      {:type => :point, :name => 'warehouse', :label => 'Warehouse'},
      {:type => :point, :name => 'win-stack', :label => 'Stack of pinned cactus windows.'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def tile_windows
    x = @vals['win-stack.x'].to_i
    y = @vals['win-stack.y'].to_i
    @piler = Piler.new
    @windows = @piler.pile_stack(x, y)
  end

  def init_stuff
    tile_windows

    x = @vals['warehouse.x'].to_i
    y = @vals['warehouse.y'].to_i
    @warehouse = PinnableWindow.from_point(Point.new(x, y))
    @coords = WorldLocUtils.parse_world_path(@vals['path'])

    # Count the number of non-coordinates, and make sure that matches
    # the number of wondows.
    harvests = @coords.select {|e| e.kind_of?(String) && e == 'Collect'}.size
    if @windows.size != harvests
      msg = "The path provided ask for #{harvests} harvests,\nbut there are #{@windows.size} windows."
      UserIO.error(msg)
      return nil
    end
    true
  end

  def gather(w)
    wait_for_collect(w)
    while w.click_on('Collect')
      w.refresh 'lc'
      sleep 0.05
    end
  end

  def wait_for_collect(w)
    w.refresh
    until w.read_text =~ /(2|3|4|5|6) drops/
      sleep(3)
      w.refresh
    end
  end

  def act
    return unless init_stuff
    walker = Walker.new
    loop do
      windows = @windows.reverse
      @piler.swap
      @coords.each do |c|
        if c.kind_of? Array
          walker.walk_to(c)
        elsif c == 'Stash'
          stash
        else
          w = windows.shift
          gather(w)
          @piler.pile(w)
        end
      end
    end
  end

  def stash
    @warehouse.refresh
    HowMuch.max if @warehouse.click_on('Stash/Cactus')
  end

end
Action.add_action(CactusRun.new)
