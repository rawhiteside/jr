require 'action'
require 'walker'

class TreeRun < Action
  def initialize
    super('Tree run', 'Gather')
  end

  def setup(parent)
    gadgets = [
      {:type => :world_path, :label => 'Path to walk.', :name => 'path', 
       :aux => ['Gather Wood', 'Water Mine 1', 'Water Mine 2']},
      {:type => :point, :name => 'bonfire', :label => 'Bonfire'},
      {:type => :point, :name => 'win-stack', :label => 'Stack of pinned tree windows.'},
      {:type => :point, :name => 'water-mine-1', :label => 'Water mine 1'},
      {:type => :point, :name => 'water-mine-2', :label => 'Water mine 2'},
    ]
    @vals = UserIO.prompt(parent, 'Trees', 'Trees', gadgets)
  end

  def tile_windows
    x = @vals['win-stack.x'].to_i
    y = @vals['win-stack.y'].to_i
    tiler = Tiler.new(2, 85)
    tiler.y_offset = 10
    @windows = tiler.tile_stack(x, y, 0.1)
  end

  def init_stuff
    tile_windows

    @bonfire = PinnableWindow.from_point(point_from_hash(@vals, 'bonfire'))
    water_mine_1 = PinnableWindow.from_point(point_from_hash(@vals, 'water-mine-1'))
    water_mine_2 = PinnableWindow.from_point(point_from_hash(@vals, 'water-mine-2'))
    @mine_worker1 = WaterMineWorker.new(water_mine_1)
    @mine_worker2 = WaterMineWorker.new(water_mine_2)

    @coords = WorldLocUtils.parse_world_path(@vals['path'])

    # Count the number of Harvest requests, and make sure that matches
    # the number of windows.
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
        elsif c == 'Gather Wood'
          gather(windows.shift)
        elsif c == 'Water Mine 1'
          @mine_worker1.tend
        elsif c == 'Water Mine 2'
          @mine_worker2.tend
        end
      end

      @bonfire.refresh
      HowMuch.new(:max) if @bonfire.click_on('Add')

    end
  end
end
Action.add_action(TreeRun.new)

