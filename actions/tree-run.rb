require 'action'
require 'walker'

class TreeRun < Action
  def initialize
    super('Tree run', 'Gather')
  end

  def setup(parent)
    gadgets = [
      {:type => :world_path, :label => 'Path to walk.', :name => 'path', :aux => 'Gather Wood'},
      {:type => :point, :name => 'bonfire', :label => 'Bonfire'},
      {:type => :point, :name => 'win-stack', :label => 'Stack of pinned tree windows.'},
    ]
    @vals = UserIO.prompt(parent, 'Trees', 'Trees', gadgets)
  end

  def tile_windows
    x = @vals['win-stack.x'].to_i
    y = @vals['win-stack.y'].to_i
    tiler = Tiler.new(2, 77)
    tiler.y_offset = 20
    @windows = tiler.tile_stack(x, y, 0.2)
  end

  def init_stuff
    tile_windows

    x = @vals['bonfire.x'].to_i
    y = @vals['bonfire.y'].to_i
    @bonfire = PinnableWindow.from_point(Point.new(x, y))
    @coords = WorldLocUtils.parse_world_path(@vals['path'])

    # Count the number of non-coordinates, and make sure that matches
    # the number of wondows.
    harvests = @coords.select {|e| e.kind_of? String}.size
    if @windows.size != harvests
      msg = "The path provided ask for #{harvests} harvests,\nbut there are #{@windows.size} windows."
      UserIO.error(msg)
      return nil
    end
    true
  end

  def gather(w)
    loop do
      w.refresh
      break if w.click_on('Gather')
      sleep_sec 2
    end
    # Wait for the gather before we start walking.  The menu will turn
    # to "Fertilize"
    wait_for_fert(w)
  end

  def wait_for_fert(w)
    loop do
      sleep_sec 0.5
      w.refresh
      return if w.read_text =~ /Fertilize/
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
        else
          gather(windows.shift)
        end
      end

      @bonfire.refresh
      HowMuch.new(:max) if @bonfire.click_on('Add')

    end
  end
end
Action.add_action(TreeRun.new)

