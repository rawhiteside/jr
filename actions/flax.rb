require 'action'
require 'walker'
require 'user-io'

# Plant centered aligned with --Jaby-- lines in name.
class FlaxGrow < Action
  def initialize
    super('Grow flax', 'Plants')
    @threads = []
    @walker = Walker.new
  end

  def get_plant_menu(parent, t)
    # Coords are relative to your head in cart view.
    gadgets = [
      {:type => :point, :label => 'Drag onto the pinned plant on your head',
	:name => 'plant'},
      {:type => :point, :label => 'Drag the pinned stash dialog',
	:name => 'stash'},
      {:type => :number, :label => 'How many crops?',
	:name => 'count'},
    ]
    return UserIO.prompt(parent, t, t, gadgets)
  end

  def setup(parent)
    @vals = get_plant_menu(parent, 'flax-grow')
  end

  FIRST_PLANT_WORLD_COORDS = [4543, -5877]
  WH_WORLD_COORDS=[4547,-5872]
  WATER_WORLD_COORDS=[4547,-5866]
  def act
    @center = [@vals['plant.x'].to_i, @vals['plant.y'].to_i]
    @count = @vals['count'].to_i
    stash_point = point_from_hash(@vals, 'stash')
    @stash_win = PinnableWindow.from_point(stash_point)

    loop do
      @count.times {grow_one_crop}

      @walker.walk_to(WH_WORLD_COORDS)
      @stash_win.refresh
      @stash_win.click_on('Stash/Flax')
      HowMuch.new(:max)
      @stash_win.click_on('Stash/Insect/Stash All')
      @stash_win.click_on('Stash/Flax See/All')
      @stash_win.click_on('Take/Flax See/Nile')
      HowMuch.new(@count * 50)
      
      @walker.walk_to(WATER_WORLD_COORDS)
      refill
    end
  end

  def refill
    with_robot_lock do
      rclick_at(341, 86)
      HowMuch.new(:max)
      sleep_sec 0.4
    end
  end

  def step_patterns(size)
    if size == 2
      return [ [:right], [:down], [:left], ]
    elsif size == 3
      return [
	[:right], [:right],
	[:down], [:down],
	[:left],[:left],
	[:up],
	[:right],
      ]
    elsif size == 5
      return [
	[:right], [:right],[:right], [:right],
	[:down], [:down],[:down], [:down],
	[:left],[:left],[:left],[:left],
	[:up],[:up],[:up],
	[:right],
      ] + step_patterns(3)
    elsif size == 7
      return [
	[:right], [:right],[:right], [:right],
	[:right], [:right],
	[:down], [:down],[:down], [:down],[:down],
	[:down],
	[:left],[:left],[:left],[:left],[:left],
	[:left],
	[:up],[:up],[:up],[:up],[:up],
	[:right],
      ] + step_patterns(5)
    end
  end

  # An array of :ne, :nw, :se, :sw, indicating
  # the best place to pop the menu for this bed
  # 
  # Sometimes the plants overlap, because walking isn't
  # perfect.  This prevents popping the wrong bed.
  def pop_locations(size)
      # Don't include the *first* bed in the list
      # Just 48 plants.
    symbols = [
      [:ne] * 6, # right
      [:se] * 6, # down
      [:sw] * 6, # left
      [:nw] * 4, :sw, # up to first row.
      [:se] * 4, :sw, # right
      [:sw] * 3, :nw, # down
      [:nw] * 3, :ne, # right
      [:ne] * 2, :se, # up
      [:se] * 2, :sw, # right
      :sw, :nw, # down
      :nw, :ne, # left
      :se, # up
      :sw, # right
    ].flatten
    if symbols.size != 48
      return nil
    end
    coords = {
      :ne => [@center[0] + 60, @center[1] - 60], 
      :se => [@center[0] + 60, @center[1] + 60], 

      :nw => [@center[0] - 60, @center[1] - 60], 
      :sw => [@center[0] - 60, @center[1] + 60], 

    }
    return symbols.collect {|s| coords[s]}
  end


  
  # Time to hold down the key to take a good step.
  KEY_DELAY = 0.01

  def grow_one_crop
    @walker.walk_to(FIRST_PLANT_WORLD_COORDS)
    size = 7
    plots = step_patterns(size)
    dlg_locs = tile_locations
    pop_locs = pop_locations(7)

    @threads = []

    # Plant the first one
    spawn(plant([@center[0]+60, @center[1] - 60], dlg_locs.shift))

    plots.each do |s|
      @walker.steps(s, KEY_DELAY)
      spawn(plant(pop_locs.shift, dlg_locs.shift))
    end

    @threads.each {|t| t.join }
  end

  def spawn(dlg)
    @threads << ControllableThread.new do
      dlg.tend
    end
  end

  def tile_locations
    row = []
    7.times {|i| row << [i * 173, 26] }
    locs = []
    # Four rows
    4.times do |y|
      locs += row.collect {|e| [e[0], 26 + 101 * y] }
    end
    # Then a gap, and three more rows.
    3.times do |y|
      locs += row.collect {|e| [e[0], 615 + 101 * y] }
    end

    locs
  end

  def stop
    @threads.each {|t| t.kill} if @threads
    super
  end

  def plant(pop_loc, dlg_loc)
    plant = @center
    rclick_at(*plant)

    dlg = nil
    with_robot_lock do
      dlg = PinnableWindow.from_screen_click(Point.new(pop_loc[0], pop_loc[1])).pin
      dlg = FlaxPlantWindow.new(dlg.get_rect)
      dlg.drag_to(Point.new(dlg_loc[0], dlg_loc[1]))
    end
    return dlg
  end

end

class FlaxPlantWindow < PinnableWindow

  # First water/weed is at ~35 seconds (seeds at 50)
  FIRST_WAIT = 35
  SECOND_WAIT = 16
  THIRD_WAIT = 15
  W_PROBE = [11, 72-26]
  H_PROBE = [10, 79-26]

  # Returns when the flax bed is gone.
  def tend
    done = tend_once(FIRST_WAIT, W_PROBE, H_PROBE)
    done ||= tend_once(SECOND_WAIT, W_PROBE, H_PROBE)
    done ||= tend_once(THIRD_WAIT, H_PROBE, H_PROBE)
    unpin
  end

  # we start doing this while walking.  Thus, the
  # dialog may look OK, but then by the time we
  # click on the menu, we've walked out of range.
  #
  # Loop until we click, and the dialog looks OK afterward
  # then return false.
  # If we see the harvest probe return true
  def tend_once(initial_wait, probe, harvest_probe)
    # A black spot in the dialog title
    dialog_OK = [136, 40 - 25]
      
    # Wait for the "water/weed" to appear
    sleep_sec(initial_wait)
    all_done = false
    loop do
      refresh
      until dialog_pixel(Point.new(*probe)) == 0
	if dialog_pixel(Point.new(*harvest_probe)) == 0
	  all_done = true
	  break
	end
	sleep_sec 3;
	refresh;
      end
      dialog_click(Point.new(*probe))
      # See if the dialog now looks OK.
      sleep_sec 3
      return all_done if all_done || dialog_pixel(Point.new(*dialog_OK)) == 0
    end
  end

end

FLAX_DATA = {
  'Constitution Peak' => {},
  "Jacob's Field" => {},
  "Nile Green" => {},
  "Old Dog" => {},
  "Old Egypt" => {},
  "Sunset Pond" => {},
  "Symphony Ridge Gold" => {},
}

class FlaxSeeds < Action
  HARVEST_DELAY = 0.2

  def initialize
    super('Flax Seeds', 'Plants')
    @walker = Walker.new
  end

  def setup(parent)
    # Coords are relative to your head in cart view.
    gadgets = [
      {:type => :combo, :label => 'What type of flax?', :name => 'flax-type', 
       :vals => FLAX_DATA.keys.sort},
      {:type => :point, :label => 'Drag onto your head', :name => 'head'},
      {:type => :point, :label => 'Drag onto warehouse menu', :name => 'stash'},
      {:type => :number, :label => 'How many major loops? (3 for carry 500)', :name => 'repeat'},
      {:type => :number, :label => 'Max wait seconds for harvest', :name => 'max_wait_secs'},
      {:type => :number, :label => "How many havests from each plant?", :name => 'harvest_reps'},
      {:type => :number, :label => 'Length of each of the two rows', :name => 'row_len'},
      {:type => :world_loc, :label => 'Start planting here (Eastwards)', :name => 'start_location'},
      {:type => :world_loc, :label => 'Location near the stash cest', :name => 'stash_location'},
    ]

    @vals =  UserIO.prompt(parent, 'flax-seeds', 'flax-seeds', gadgets)
  end

  def act
    head = [@vals['head.x'].to_i, @vals['head.y'].to_i]
    repeat = @vals['repeat'].to_i
    @flax_type = @vals['flax-type']
    @harvest_reps = @vals['harvest_reps'].to_i
    @row_len = @vals['row_len'].to_i
    @start_location = WorldLocUtils.parse_world_location(@vals['start_location'])
    @stash_location = WorldLocUtils.parse_world_location(@vals['stash_location'])
    @max_wait_secs = @vals['max_wait_secs'].to_i

    @w_plant = get_plant_window
    stash_chest = PinnableWindow.from_point(point_from_hash(@vals, 'stash'))
    return unless @w_plant
    walker = Walker.new
    loop do
      # 
      # Go stash whatever you have, and pick up seeds.
      walker.walk_to(@stash_location)
      stash_chest.click_on('Stash./Flax/All')
      stash_chest.click_on("Take/Flax Seeds/#{@flax_type}")
      HowMuch.new(2*@row_len + 1)

      # Plant and harvest. 
      repeat.times do
	walker.walk_to(@start_location)
	sleep_sec 0.5
	plant(head)
	harvest
	sleep_sec 1
      end
    end
  end

  def rip_out(w)
    # Wait for "Harvest" to complete
    loop do
      w.refresh
      return if w.read_text.strip == ''
      break if w.find_matching_line('The seeds')
      sleep_sec 0.2
    end
    # try 3 times to rip
    3.times do
      break if w.click_on('Util/Rip')
    end
  end

  def harvest
    (@harvest_reps - 1).times { @windows.each {|w| harvest_one(w)}}
    @windows.each do |w|
      harvest_one(w)
      rip_out(w)
      w.refresh
      w.unpin
    end
    
  end

  def harvest_one(w)
    start = Time.now
    loop do
      w.refresh
      # 
      # Error handling.  If the menu is empty, just ignore it.
      return if w.read_text.strip == ''

      break if w.click_on('Harvest')
      # 
      # Error handling.  If the Harvest doesn't appear within
      # max_wait_secs secs, assume thw worst.
      return if (Time.now - start) > @max_wait_secs
      sleep_sec 0.5
    end
    sleep_sec HARVEST_DELAY
  end

  def plant(head)
    @tiler = Tiler.new(0, 77, 0.45)
    @tiler.y_offset = 17
    @windows = []
    # 
    # Plant a row to the right.
    
    loc = [head[0] + 100, head[1]]
    (@row_len-1).times {
      plant_and_pin(loc)
      @walker.right
      sleep_sec(0.1)
    }

    # Plant one more and step down
    plant_and_pin(loc)
    @walker.down
    @walker.down

    # Now, plant the lower row
    loc = [head[0] - 100, head[1] + 100]
    @row_len.times {
      plant_and_pin(loc)
      @walker.left
    }
  end

  # +loc+: A spot on the just-planted flax to the right, used to pick up
  # the menu
  # Also, uses the @tiler, and appends the window to @windows
  def plant_and_pin(loc)
    @w_plant.click_on(@flax_type)
    w = PinnableWindow.from_screen_click(Point.new(loc[0], loc[1]))
    w.stable = true
    w.pin
    @tiler.tile(w)
    @windows << w
    w.stable = false
  end

  def get_plant_window
    w = PinnableWindow.from_point(Point.new(93, 30))
    UserIO.error('Did not find plant menu in upper left corner') unless w
    w
  end


end

Action.add_action(FlaxGrow.new)
Action.add_action(FlaxSeeds.new)
