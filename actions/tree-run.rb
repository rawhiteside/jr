require 'action'
require 'walker'

class TreeRun < Action
  def initialize
    super('Tree run', 'Gather')
  end

  def persistence_name
    'Trees'
  end

  def setup(parent)
    gadgets = [
      {:type => :world_path, :label => 'Path to walk.', :name => 'path',
       :rows => 20,
       :aux => ['Gather Wood', 'Water Mine 1', 'Water Mine 2', 'Water Mine 3', 'Bonfire Stash', 'Storage Stash', 'Greenhouse']},
      {:type => :point, :name => 'storage', :label => 'Drag to pinned bonfire or storage'},
      {:type => :point, :name => 'win-stack', :label => 'Drag to stack of pinned tree windows.'},


      {:type => :point, :name => 'water-mine-1', :label => 'Water mine 1'},
      {:type => :point, :name => 'water-mine-2', :label => 'Water mine 2'},
      {:type => :point, :name => 'water-mine-3', :label => 'Water mine 3'},
      {:type => :number, :name => 'scan-interval-1', :label => 'WM2: Angle scan interval 1 (minutes)'},
      {:type => :number, :name => 'scan-interval-2', :label => 'WM2: Angle scan interval 2 (minutes)'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def stop
    @mine_worker1.log_action('Stop') if @mine_worker1
    @mine_worker2.log_action('Stop') if @mine_worker2
    @mine_worker3.log_action('Stop') if @mine_worker3
    super
  end

  def tile_windows
    x = @vals['win-stack.x'].to_i
    y = @vals['win-stack.y'].to_i

    @piler = Piler.new
    @windows = @piler.pile_stack(x, y)
  end

  def init_stuff
    @windows = []
    path_text = @vals['path']

    if path_text.include?('Gather')
      tile_windows
    end
      

    if path_text.include?('Stash')
      @storage = PinnableWindow.from_point(point_from_hash(@vals, 'storage'))
    end

    @mine_worker1 = nil
    if path_text.include? 'Water Mine 1'
      water_mine = PinnableWindow.from_point(point_from_hash(@vals, 'water-mine-1'))
      scan_interval_1 = @vals['scan-interval-1'].to_i
      scan_interval_2 = @vals['scan-interval-2'].to_i
      @mine_worker1 = WaterMineWorker.new(water_mine, scan_interval_1 * 60, scan_interval_2 * 60)
    end

    @mine_worker2 = nil
    if path_text.include? 'Water Mine 2'
      water_mine = PinnableWindow.from_point(point_from_hash(@vals, 'water-mine-2'))
      scan_interval_1 = @vals['scan-interval-1'].to_i
      scan_interval_2 = @vals['scan-interval-2'].to_i
      @mine_worker2 = WaterMineWorker.new(water_mine, scan_interval_1 * 60, scan_interval_2 * 60)
    end

    @mine_worker3 = nil
    if path_text.include? 'Water Mine 3'
      water_mine = PinnableWindow.from_point(point_from_hash(@vals, 'water-mine-3'))
      scan_interval_1 = @vals['scan-interval-1'].to_i
      scan_interval_2 = @vals['scan-interval-2'].to_i
      @mine_worker3 = WaterMineWorker.new(water_mine, scan_interval_1 * 60, scan_interval_2 * 60)
    end

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
    sleep_sec 0.05
    text = w.read_text
    match = Regexp.new('no Wood for ([0-9]+) ').match(text)

    match ? match[1].to_i : 0
  end    

  def gather(w)

    # Wait for wood to be available, then gather it
    # If it's going to be over 15 sec, then skip it.
    loop do
      return if (secs = secs_to_wait(w)) > 20
      break if w.click_on('Gather')
      sleep_sec 2
    end

    # Wait for the gather before we start walking.  The menu will turn
    # to "Fertilize"
    wait_for_fert(w)
  end

  def wait_for_fert(w)
    loop do
      w.refresh
      return if w.read_text =~ /Fertilize/
      sleep_sec 0.5
    end
  end

  def act
    return unless init_stuff
    walker = Walker.new
    loop do
      if @windows.size > 0
        windows = @windows.reverse
        @piler.swap
      end
      @coords.each do |c|
        if c.kind_of? Array
          walker.walk_to(c)
        elsif c == 'Gather Wood'
          w = windows.shift
          gather(w)
          @piler.pile(w)
        elsif c == 'Water Mine 1'
          @mine_worker1.tend
        elsif c == 'Water Mine 2'
          @mine_worker2.tend
        elsif c == 'Water Mine 3'
          @mine_worker3.tend
        elsif c == 'Greenhouse'
          harvest_greenhouse
        elsif c == 'Bonfire Stash'
          bonfire_stash(@storage)
        elsif c == 'Storage Stash'
          storage_stash(@storage)
        end
      end
    end
  end

  # Just spam "H" near the center of the screen.  Should be standing
  # in the GH, and the whole area is active.
  def harvest_greenhouse
    dim = screen_size
    sleep_sec 0.1
    mm(dim.width/2, dim.height/2 + 100)
    sleep_sec 0.1
    send_string 'h'
    sleep_sec 0.1
    mm(dim.width/2, dim.height/2 - 100)
    sleep_sec 0.1
    send_string 'h'
    sleep_sec 0.1
  end
  
  def bonfire_stash(bonfire)
    bonfire.refresh
    sleep 0.2
    HowMuch.max if bonfire.click_on('Add')
  end

  def storage_stash(storage)
    storage.refresh
    sleep 0.2
    HowMuch.max if storage.click_on('Stash./Wood')
    storage.click_on('Stash./Insect/All')
  end
end
Action.add_action(TreeRun.new)

