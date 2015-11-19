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
    @vals = UserIO.prompt(parent, 'Cactus', 'Cactus', gadgets)
  end

  def tile_windows
    x = @vals['win-stack.x'].to_i
    y = @vals['win-stack.y'].to_i
    tiler = Tiler.new(2, 85)
    tiler.y_offset = 5
    @windows = tiler.tile_stack(x, y, 0.1)
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
      sleep_sec 0.05
    end
  end

  def wait_for_collect(w)
    w.refresh
    until w.read_text =~ /(2|3) drops/
      sleep_sec(3)
      w.refresh
    end
  end

  def act
    return unless init_stuff
    walker = Walker.new
    loop do
      windows = @windows.reverse
      @coords.each do |c|
        if c.kind_of? Array
          walker.walk_to(c)
        elsif c == 'Stash'
          stash
        else
          gather(windows.shift)
        end
      end

    end
  end

  def stash
    @warehouse.refresh
    HowMuch.new(:max) if @warehouse.click_on('Stash/Cactus')
  end

end
Action.add_action(CactusRun.new)
