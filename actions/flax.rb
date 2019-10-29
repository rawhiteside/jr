require 'action'
require 'walker'
require 'user-io'

FLAX_DATA = {
  'Constitution Peak' => {},
  "Jacob's Field" => {},
  "Nile Green" => {},
  "Old Dog" => {:water => 2},
  "Old Egypt" => {},
  "Sunset Pond" => {},
  "Symphony Ridge Gold" => {:water => 0},
}

# Plant centered aligned with --Jaby-- lines in name.
class FlaxGrow < Action



  def initialize
    super('Grow flax', 'Plants')
    @walker = Walker.new
  end

  def setup(parent)
    # Coords are relative to your head in cart view.
    gadgets = [
      {:type => :combo, :label => 'What type of flax?', :name => 'flax-type', 
       :vals => FLAX_DATA.keys.sort},
      {:type => :point, :label => 'Drag onto the pinned plant.', :name => 'plant'},
      {:type => :point, :label => 'Drag onto your head.', :name => 'head'},
      {:type => :point, :label => 'Drag the pinned stash dialog', :name => 'stash'},
      {:type => :number, :label => 'How many crops?', :name => 'count'},
      {:type => :number, :label => 'How many rows?', :name => 'rows'},
      {:type => :number, :label => 'How many columns?', :name => 'cols'},
      {:type => :world_loc, :label => 'Grow starting location', :name => 'grow'},
      {:type => :world_loc, :label => 'Location of water', :name => 'water'},
      {:type => :world_loc, :label => 'Location near stash', :name => 'stash'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  # Flax bed pop locations for the previous step
  def pop_points_for_previous_step(center)
    offset = 180
    {
      # When no previous step
      :none => Point.new(center[0] + offset, center[1]), 
      :right => Point.new(center[0] + offset, center[1]), 
      :left => Point.new(center[0] - offset, center[1]), 
      :down => Point.new(center[0], center[1] + offset), 
    }
  end


  def act

    center = [@vals['head.x'].to_i, @vals['head.y'].to_i]
    pop_points = pop_points_for_previous_step(center)

    count = @vals['count'].to_i
    stash_point = point_from_hash(@vals, 'stash')
    stash_win = PinnableWindow.from_point(stash_point)
    plant_win = PinnableWindow.from_point(point_from_hash(@vals, 'plant'))
    @flax_type = @vals['flax-type']
    @plant_point = plant_win.coords_for(@flax_type)
                                           

    water_count = FLAX_DATA[@flax_type][:water]
    @plant_wl = WorldLocUtils.parse_world_location(@vals['grow'])
    @water_wl = WorldLocUtils.parse_world_location(@vals['water']) if water_count > 0
    @stash_wl = WorldLocUtils.parse_world_location(@vals['stash'])
    @rows = @vals['rows'].to_i
    @cols = @vals['cols'].to_i

    loop do
      count.times {grow_one_batch(pop_points)}

      stash_and_get(stash_win, count * @rows * @cols) if stash_win

      # Refill with water.
      if water_count > 0
        @walker.walk_to(@water_wl)
        refill
      end
    end
  end

  # Walk to chess, Stash the flax, and get seeds for another round
  def stash_and_get(stash_win, count)
      @walker.walk_to(@stash_wl)
      stash_win.refresh
      stash_win.click_on('Stash./Flax')
      HowMuch.max
      stash_win.click_on('Stash./Insect/Stash All')
      stash_win.click_on('Stash./Flax See/All')
      stash_win.click_on("Take/Flax See/#{@flax_type}")
      HowMuch.amount(count + 1)
  end

  def refill
    with_robot_lock do
      Icons.refill
    end
  end

  def step_patterns(rows, cols)
    steps = [:none]
    rows.times do |irow|
      if (irow % 2 == 0)
        steps << [:right] * (cols-1)
      else
        steps << [:left] * (cols-1)
      end
      steps << [:down] unless irow == rows - 1
    end
    
    return steps.flatten
  end


  
  # Time to hold down the key to take a good step.
  KEY_DELAY = 0.01
  
  def grow_one_batch(pop_points)
    @walker.walk_to(@plant_wl)
    windows = []

    tiler = Tiler.new(0, 100)
    tiler.min_width = 312
    tiler.min_height = (153 - 23)
    tiler.y_offset = 5

    plots = step_patterns(@rows, @cols)
    plots.each do |s|
      @walker.steps([s], KEY_DELAY) unless s == :none
      dlg = plant(pop_points[s])
      tiler.tile(dlg)
      windows << dlg
    end
    # Tend the beds in sequence.
    until windows.size == 0 do
      active_windows = []
      windows.each do |w|
        active_windows << w if tend(w) 
      end
      windows = active_windows
    end
  end

  # Do something useful to the flax bed.
  # true if there's more to do later.
  # false if you harvest
  def tend(dlg)
    if dlg.notation != 'Harvested'
      loop do
        # Make sure the dialog is still there.
        dlg.refresh
        text = dlg.read_text
        return true if dlg.click_on("Water") || dlg.click_on("Weed")
        if dlg.click_on("Harvest seeds")
          dlg.click_on("Util/Rip")
          dlg.unpin
          return false
        end
        if dlg.click_on("Harvest this")
          dlg.notation = 'Harvested'
          return true
        end
        sleep_sec 1.0
      end
    end

    # Wait for the dialog to be empty. 
    loop do
      dlg.refresh
      text = dlg.read_text
      if text.include?("Harvest")
        dlg.click_on("Harvest")
      else
        break
      end
      sleep_sec 1.0
    end

    # Finally, if somethign messed up, and we just harvested seeds up there. rip it out.
    dlg.click_on('Util/Rip')

    # Dialog went away.  
    dlg.unpin
    return false
  end

                

  def plant(pop_point)
    rclick_at(@plant_point)
    dlg = nil
    3.times do
      with_robot_lock do
        dlg = PinnableWindow.from_screen_click(pop_point).pin
      end
      text = dlg.read_text
      break if text.include?('This is your Flax Bed')
      dlg.unpin
      puts 'Hit avatar instead of flax bed.  Retrying.'
      sleep 0.2
    end
    return dlg
  end

end

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
      {:type => :point, :label => 'Drag onto plant menu', :name => 'plant'},
      {:type => :number, :label => 'How many major loops? (3 for carry 500)', :name => 'repeat'},
      {:type => :number, :label => 'Max wait seconds for harvest', :name => 'max_wait_secs'},
      {:type => :number, :label => "How many havests from each plant?", :name => 'harvest_reps'},
      {:type => :number, :label => 'Length of each of the two rows', :name => 'row_len'},
      {:type => :world_loc, :label => 'Start planting here (Eastwards)', :name => 'start_location'},
      {:type => :world_loc, :label => 'Location near the stash cest', :name => 'stash_location'},
      {:type => :combo, :name => 'first_dir', :label => 'Starting direction:',
       :vals => ['left', 'right']},
      ]

    @vals =  UserIO.prompt(parent, persistence_name, action_name, gadgets)
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


    @w_plant = PinnableWindow.from_point(point_from_hash(@vals, 'plant'))
    stash_chest = PinnableWindow.from_point(point_from_hash(@vals, 'stash'))
    return unless @w_plant
    walker = Walker.new
    loop do
      # 
      # Go stash whatever you have, and pick up seeds.
      if stash_chest
        walker.walk_to(@stash_location)
        stash_chest.click_on('Stash./Flax/All')
        stash_chest.click_on("Take/Flax Seeds/#{@flax_type}")
        HowMuch.amount(2*@row_len + 1)
      end

      
      # Plant and harvest. 
      first_dir = @vals['first_dir']
      repeat.times do
        @piler = Piler.new
	walker.walk_to(@start_location)
	sleep_sec 0.5
	plant(head, first_dir)
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
    (@harvest_reps - 1).times do
      @piler.swap
      @windows.each do |w|
        harvest_one(w)
        @piler.pile(w)
      end
    end

    @windows.each do |w|
      harvest_one(w)
      rip_out(w)
      w.refresh
      w.unpin
      sleep_sec 0.1
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

  def plant(head, first_dir)
    @windows = []
    # 
    # Plant a row to the right.
    
    loc = [head[0] + 100, head[1]]
    (@row_len-1).times {
      plant_and_pin(loc)
      first_dir == 'right' ? @walker.right : @walker.left 
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
      first_dir == 'left' ? @walker.right : @walker.left 
    }
  end

  # +loc+: A spot on the just-planted flax to the right, used to pick up
  # the menu
  # Also, uses the @tiler, and appends the window to @windows
  def plant_and_pin(loc)
    @w_plant.click_on(@flax_type)
    w = PinnableWindow.from_screen_click(Point.new(loc[0], loc[1]))
    if w
      w.pin
      @piler.pile(w)
      @windows << w
    end
  end

end

Action.add_action(FlaxGrow.new)
Action.add_action(FlaxSeeds.new)
