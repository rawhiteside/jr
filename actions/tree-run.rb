require 'action'
require 'walker'

class TreeRun < Action
  def initialize
    super('Tree run', 'Gather')
  end

  def setup(parent)
    gadgets = [
      {:type => :world_path, :label => 'Path to walk.', :name => 'path', 
       :aux => ['Gather Wood', 'Water Mine 1', 'Water Mine 2', 'Bonfire Stash']},
      {:type => :point, :name => 'bonfire', :label => 'Bonfire'},
      {:type => :point, :name => 'win-stack', :label => 'Stack of pinned tree windows.'},
      {:type => :point, :name => 'water-mine-1', :label => 'Water mine 1'},
      {:type => :number, :name => 'scan-interval-wm1-1', :label => 'WM1: Angle scan interval 1 (minutes)'},
      {:type => :number, :name => 'scan-interval-wm1-2', :label => 'WM1: Angle scan interval 2 (minutes)'},
      {:type => :point, :name => 'water-mine-2', :label => 'Water mine 2'},
      {:type => :number, :name => 'scan-interval-wm2-1', :label => 'WM2: Angle scan interval 1 (minutes)'},
      {:type => :number, :name => 'scan-interval-wm2-2', :label => 'WM2: Angle scan interval 2 (minutes)'},
    ]
    @vals = UserIO.prompt(parent, 'Trees', 'Trees', gadgets)
  end

  def stop
    @mine_worker1.log_action('Stop') if @mine_worker1
    @mine_worker2.log_action('Stop') if @mine_worker2
    super
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

    water_mine = PinnableWindow.from_point(point_from_hash(@vals, 'water-mine-1'))
    scan_interval_1 = @vals['scan-interval-wm1-1'].to_i
    scan_interval_2 = @vals['scan-interval-wm1-2'].to_i
    @mine_worker1 = WaterMineWorker.new(water_mine, scan_interval_1 * 60, scan_interval_2 * 60)

    water_mine = PinnableWindow.from_point(point_from_hash(@vals, 'water-mine-2'))
    scan_interval_1 = @vals['scan-interval-wm2-1'].to_i
    scan_interval_2 = @vals['scan-interval-wm2-2'].to_i
    @mine_worker2 = WaterMineWorker.new(water_mine, scan_interval_1 * 60, scan_interval_2 * 60)

    @coords = WorldLocUtils.parse_world_path(@vals['path'])

    # Count the number of wood Hwrvest requests, and make sure that
    # matches the number of wondows.
    harvests = @coords.select {|e| e.kind_of?(String)&& e =~ /Gather/}.size
    if @windows.size != harvests
      msg = "The path provided ask for #{harvests} harvests,\nbut there are #{@windows.size} windows."
      UserIO.error(msg)
      return nil
    end
    true
  end

  def secs_to_wait(w)
    w.refresh
    sleep_sec 0.5
    text = w.read_text
    match = Regexp.new('no Wood for ([0-9]+) ').match(text)

    match ? match[1].to_i : 0
  end    

  def gather(w)
    loop do
      return if (secs = secs_to_wait(w)) > 15
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
        elsif c == 'Bonfire Stash'
          bonfire_stash(@bonfire)
        end
      end
      


    end
  end

  def bonfire_stash(bonfire)
    bonfire.refresh
    sleep 0.2
    bonfire.refresh
    sleep 0.2
    HowMuch.new(:max) if bonfire.click_on('Add')
  end
end
Action.add_action(TreeRun.new)

