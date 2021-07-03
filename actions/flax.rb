require 'action'
require 'walker'
require 'user-io'

FLAX_DATA = {
  'Constitution Peak' => {},
  "Jacob" => {},
  "Nile Green" => {},
  "Old Dog" => {:water => 2},
  "Old Egypt" => {},
  "Sunset Pond" => {},
  "Symphony Ridge Gold" => {:water => 0},
}

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
      {:type => :point, :label => 'Drag the pinned stash dialog', :name => 'stash'},
      {:type => :number, :label => 'How many crops?', :name => 'count'},
      {:type => :number, :label => 'How many rows?', :name => 'rows'},
      {:type => :number, :label => 'How many columns?', :name => 'cols'},
      {:type => :world_loc, :label => 'Grow starting location', :name => 'grow'},
      {:type => :world_loc, :label => 'Location of water', :name => 'water'},
      {:type => :world_loc, :label => 'Location near stash', :name => 'stash'},
      {:type => :number, :label => 'Plant delay', :name => 'plant-delay'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  # Flax bed pop locations for the previous step
  def pop_points_for_previous_step(center)
    offset = 130
    {
      # When no previous step
      :none => Point.new(center[0] + offset, center[1] + offset),
      :right => Point.new(center[0] + offset, center[1] + offset),
      :left => Point.new(center[0] - offset, center[1] + offset),
      :down => Point.new(center[0], center[1] + offset),
    }
  end


  def act

    dim = screen_size
    center = [dim.width/2, dim.height/2]
    pop_points = pop_points_for_previous_step(center)

    count = @vals['count'].to_i
    stash_point = point_from_hash(@vals, 'stash')
    stash_win = PinnableWindow.from_point(stash_point)
    plant_win = PinnableWindow.from_point(point_from_hash(@vals, 'plant'))
    @flax_type = @vals['flax-type']
    @plant_point = plant_win.coords_for_line('Plant')
    @plant_delay = @vals['plant-delay'].to_f

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
  KEY_DELAY = 0.25
  
  def grow_one_batch(pop_points)
    @walker.walk_to(@plant_wl)
    windows = []

    piler = Piler.new

    plots = step_patterns(@rows, @cols)
    plots.each do |s|
      @walker.steps([s], KEY_DELAY) unless s == :none
      sleep @plant_delay
      dlg = plant(pop_points[s])
      piler.pile(dlg)
      windows << dlg
    end

    # Tend the beds in sequence.
    last_w = nil
    until windows.size == 0 do
      active_windows = []
      piler.swap
      last_w = nil
      windows.each do |w|
        if tend(w)
          if w.notation != 'Harvested'
            active_windows << w
            piler.pile(w)
          else
            # Want to wait for the last harvested window.
            # Unpin any others.  Just keep track of the last.
            last_w.unpin unless last_w.nil?
            last_w = w
            piler.pile(w)
          end
        end
      end
      windows = active_windows
    end
    # Wait for last harvested to be empty.
    if last_w
      loop do
        last_w.refresh
        text = last_w.read_text.strip
        break if text == '<pin>' || text == ''
        sleep 1
      end
      last_w.unpin
    end
  end

  # Do something useful to the flax bed.
  # true if there's more to do later.
  # false if the window gets unpinned.
  def tend(dlg)
    if dlg.notation != 'Harvested'
      loop do
        # Make sure the dialog is still there.
        dlg.refresh
        text = dlg.read_text
	if text.strip == '' 
	  dlg.unpin
	  return false
	end
        return true if water_or_weed(dlg)
        if dlg.click_on("Harvest seeds") || text.include?("seeds")
          dlg.unpin
          return false
        end
        if dlg.click_on("Harvest this")
          dlg.notation = 'Harvested'
          return true
        end
        sleep 1.0
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
      sleep 1.0
    end

    # Dialog went away.  
    dlg.unpin
    return false
  end

                
  def water_or_weed(dlg)
    if dlg.click_on("Water") || dlg.click_on("Weed")
      if dlg.read_text.include?('This is too far')
        return false
      else
        return true
      end
    else
      return false
    end
  end

  def plant(pop_point)
    # Rip out any beds that are in the way. 
    mm pop_point
    sleep 0.02
    # It's *possible* there're several overlapping. 
    send_string("RR", 0.02)

    lclick_at(@plant_point)
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
    @to_rip = nil
  end

  def setup(parent)
    # Coords are relative to your head in cart view.
    gadgets = [
      {:type => :combo, :label => 'What type of flax?', :name => 'flax-type', 
       :vals => FLAX_DATA.keys.sort},
      {:type => :point, :label => 'Drag onto warehouse menu', :name => 'stash'},
      {:type => :point, :label => 'Drag onto plant menu', :name => 'plant'},
      {:type => :number, :label => 'How many major grow/stash loops?', :name => 'repeat'},
      {:type => :number, :label => 'Max wait seconds for harvest', :name => 'max_wait_secs'},
      {:type => :number, :label => "How many havests from each plant?", :name => 'harvest_reps'},
      {:type => :number, :label => 'Length of each of the two rows', :name => 'row_len'},
      {:type => :world_loc, :label => 'Start planting here', :name => 'start_location'},
      {:type => :world_loc, :label => 'Location near the stash cest', :name => 'stash_location'},
      {:type => :combo, :name => 'first_dir', :label => 'Starting direction:',
       :vals => ['left', 'right']},
      ]

    @vals =  UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    dim = screen_size
    head = [dim.width/2, dim.height/2]
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
        stash_chest.refresh
        stash_chest.click_on('Stash./Flax/All')
        stash_chest.refresh
        stash_chest.click_on("Take/Flax Seeds/#{@flax_type}")
        HowMuch.amount(2*@row_len + 1)
      end

      
      # Plant and harvest. 
      first_dir = @vals['first_dir']
      repeat.times do
        @piler = Piler.new
	walker.walk_to(@start_location)
	sleep 0.5
	plant(head, first_dir)
	harvest
	sleep 1
      end
    end
  end

  def wait_till_gone(w)
    # Wait for "Harvest" to complete
    loop do
      w.refresh
      if w.read_text.strip == ''
        w.unpin
        return
      end
      break if w.coords_for_line('The seeds')
      sleep 0.2
    end
  end

  def harvest
    index = 0
    @windows.each {|w| w.notation = index.to_s; index += 1}

    (@harvest_reps - 1).times do |i|
      @piler.swap
      @windows.each do |w|
        harvest_one(w)
        @piler.pile(w)
      end
    end

    @piler.swap
    last_win = nil
    @windows.each do |w|
      last_win.unpin if last_win
      last_win = w
      harvest_one(w)
      @piler.pile(w)
    end
    wait_till_gone(last_win)
    last_win.unpin
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
      # max_wait_secs secs, assume the worst.
      return if (Time.now - start) > @max_wait_secs
      sleep 0.5
    end
    sleep HARVEST_DELAY
  end

  def plant(head, first_dir)
    @windows = []
    # 
    # Plant a row to the right.
    
    pop_offset = (first_dir == 'right') ? 100 : -100
    loc = [head[0] + pop_offset, head[1]]
    (@row_len-1).times {
      plant_and_pin(loc)
      first_dir == 'right' ? @walker.right : @walker.left
      sleep(0.1)
    }

    # Plant one more and step down
    plant_and_pin(loc)
    @walker.down
    @walker.down

    # Now, plant the lower row
    loc = [head[0] - pop_offset, head[1] + 100]
    @row_len.times {
      plant_and_pin(loc)
      first_dir == 'left' ? @walker.right : @walker.left 
    }
  end

  # +loc+: A spot on the just-planted flax to the right, used to pick up
  # the menu
  # Also, uses the @tiler, and appends the window to @windows
  def plant_and_pin(loc)
    # Rip anything that's there. 
    pt = Point.new(loc[0], loc[1])
    with_robot_lock do
      mm pt
      send_string 'RR', 0.05
    end

    @w_plant.click_on('Plant')
    w = PinnableWindow.from_screen_click(pt)
    if w
      w.pin
      @piler.pile(w)
      @windows << w
    end
  end

end

Action.add_action(FlaxGrow.new)
Action.add_action(FlaxSeeds.new)

class FillDistaffs < GridAction
  def initialize
    super('Distaffs', 'Buildings')
  end

  TAKE = 'Take'
  FILL = 'Fill'
  FILL_START = 'Fill and start'
  
  TASKS = [TAKE, FILL, FILL_START]
  def get_gadgets
    super  + [
      {:type => :combo, :label => 'What do to', :name => 'task', :vals => TASKS },
      {:type => :checkbox, :label => 'Skip center 4', :name => 'should-skip'},
    ]
  end

  def start_pass(index)
    @piler = Piler.new
    @windows = nil
    @spin = (@user_vals['task'] == FILL_START)
    @take_only = (@user_vals['task'] == TAKE)
  end

  def act_at(ginfo)
    return if should_skip?(ginfo)
    
    win = PinnableWindow.from_screen_click(ginfo['x'], ginfo['y'])
    
    win.pin
    @piler.pile(win)
    if @take_only
      win.click_on('Take/Everything')
      win.unpin
      return
    end
    # Maybe something left.  Take it.
    win.refresh if win.click_on('Take/Everything')

    HowMuch.max if win.click_on('Load')

    if @spin
      spin(ginfo, win)
    else
      win.unpin
    end
  end

  private
  def spin(g, win)
    if @windows.nil?
      @windows = []
      @row = g['iy']
      @window_row = []
    end

    if @row == g['iy']
      @window_row << win
    else
      # Add a new row to @window
      @window_row.reverse! if (@row % 2) == 0
      @windows << @window_row
      @window_row = [win]
      @row = g['iy']
    end
    
    if g['ix'] == (g['num-cols'] - 1) && g['iy'] == (g['num-rows'] - 1)
      # Add the last row and flatten
      @window_row.reverse! if (@row % 2) == 0
      @windows << @window_row
      @windows.flatten!
      
      # Now, start the spinning
      @windows.each do |win|
        win.refresh
        win.click_on('Start')
        win.unpin
        sleep 2
      end
    end

  end
  
  def should_skip?(p)
    return unless @user_vals['should-skip'] == 'true'

    return (2..3).cover?(p['ix']) && (3..4).cover?(p['iy'])
  end
    
end
Action.add_action(FillDistaffs.new)
