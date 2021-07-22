require 'action'
require 'window'
require 'walker'
require 'image_utils'
require 'icons'

class Barley < Action

  def initialize
    super('Barley', 'Plants')
    @pop = [670, 485]
    @dialogs = []
    @walker = Walker.new
  end


  def setup(parent)
    comps = [
      {:type => :point, :label => 'Drag onto pinned plant menu', :name => 'plant-win'},
      {:type => :point, :label => 'Drag onto pinned warehouse', :name => 'wh-win'},

      {:type => :checkbox, :label => 'Using fertilizer?', :name => 'fert?'},
      {:type => :number, :label => 'How many ticks? (2 for water-only)', :name => 'ticks'},

      {:type => :number, :label => 'How many passes until water/stash?', :name => 'count'},
      {:type => :number, :label => 'Rows in the field?', :name => 'rows'},
      {:type => :number, :label => 'Cols in the field?', :name => 'cols'},

      {:type => :world_loc, :label => 'Grow starting location', :name => 'grow-loc'},
      {:type => :world_loc, :label => 'Location of water', :name => 'water-loc'},
      {:type => :world_loc, :label => 'Location near warehouse', :name => 'wh-loc'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, comps)
  end

  def act
    dim = screen_size
    @center_x = dim.width/2 
    @center_y = dim.height/2
    @pop_for_step = pop_locations
    ticks = @vals['ticks'].to_i
    fert_p = @vals['fert?'] == "true"
    count = @vals['count'].to_i
    rows = @vals['rows'].to_i
    cols = @vals['cols'].to_i
    wh_win = PinnableWindow.from_point(point_from_hash(@vals, 'wh-win'))
    @plant_win = PinnableWindow.from_point(point_from_hash(@vals, 'plant-win'))

    wh_loc = WorldLocUtils.parse_world_location(@vals['wh-loc'])
    @grow_loc = WorldLocUtils.parse_world_location(@vals['grow-loc'])
    water_loc = WorldLocUtils.parse_world_location(@vals['water-loc'])

    stash_take_fert(rows * cols * count * (ticks + 3), wh_loc, wh_win) if fert_p
    stash_take_barley(rows * cols * count + 5, wh_loc, wh_win)

    loop do
      count.times { grow_one_field(rows, cols, ticks, fert_p) }

      # Now, refill everything for another round

      # Refill the jugs.
      @walker.walk_to(water_loc)
      Icons.refill

      
      # Stash the barley
      stash_take_barley(rows * cols * count + 5, wh_loc, wh_win)
      stash_take_fert(rows * cols * count * (ticks + 3), wh_loc, wh_win) if fert_p
    end
  end

  def stash_take_fert(amt, wh_loc, wh_win)
    @walker.walk_to(wh_loc)
    HowMuch.max if wh_win.click_on('Stash./Grain Fert')
    HowMuch.amount(amt) if wh_win.click_on('Take/Grain Fert')
  end

  def stash_take_barley(amt, wh_loc, wh_win)
    @walker.walk_to(wh_loc)
    HowMuch.max if wh_win.click_on('Stash./Grain./All')
    HowMuch.amount(amt) if wh_win.click_on('Take/Grain/Barley (Raw)')
  end

  def pop_locations
    {
      [:right] => [@center_x + 50, @center_y + 50],
      [:down] => [@center_x + 50, @center_y + 50],
      [:left] => [@center_x - 50, @center_y + 30],
      [:up] => [@center_x - 50, @center_y + 30],
    }
  end

  def plant_and_pin(pop_coords, index)

    # Dunno why, but sometimes the plant fails.  Doesn't happen with
    # other veggies...  Give an extra delay.
    w = nil
    with_robot_lock {
      unless @plant_win.click_on("Plant")
        puts "Plant failed"
        return nil
      end
      sleep 0.1
      w = PinnableWindow.from_screen_click(Point.new(pop_coords[0], pop_coords[1]))
      w = BarleyWindow.new(w.get_rect, index)
    }
    w.pin
    return w
  end

  def step_patterns(rows, cols)
    ncols = cols - 1
    nrows = rows - 1
    steps = [:right] * ncols
    loop do
      break if nrows == 0
      steps << [:down] * nrows
      break if ncols == 0
      steps << [:left] * ncols
      ncols -= 1
      nrows -= 1
      break if nrows == 0
      steps << [:up] * nrows
      break if ncols == 0
      steps << [:right] * ncols
      ncols -= 1
      nrows -= 1
    end

    steps = steps.flatten.collect{|s| [s]}
    steps << []
    return steps
  end

  def grow_one_field(rows, cols, ticks, fert_p)
    #
    check_for_pause
    @walker.walk_to(@grow_loc)
    @cascader = Cascader.new
    start_lock = JMonitor.new
    prev_patt = [:right]
    # Keep tending from starting while we plant
    index = 0
    start_lock.synchronize do
      step_patterns(rows, cols).each do |patt|
        w = plant_and_pin(pop = @pop_for_step[prev_patt], index)
        index += 1
        @cascader.stage(w)
        start_worker_thread do
	  w.tend(start_lock, ticks, fert_p)
        end
        with_robot_lock { @walker.steps(patt, 0.2) }
        prev_patt = patt
      end
      @cascader.cascade
    end
    wait_for_worker_threads
    @walker.walk_to(@grow_loc)
  end
end


class BarleyWindow < PinnableWindow
  WINDOW_UPDATE_DELAY = 0.005
  def initialize(g, index)
    @logging = false
    @index = index
    super(g)
    yoff = 26
    @locs = {
      'Water' => [240, 125],
      'Fert' => [240, 144],
      'Probe water' => [218, 125],
      'Probe fert' => [218, 145],
      'Harvest' => [130, 191],
    }
    @locs.each_key {|k| @locs[k][1] -= yoff }
  end

  def read_text
    flush_text_reader
    super
  end

  def needs_water
    dialog_color(Point.new(*@locs['Probe water'])).blue <= 200
  end
  def needs_fert
    dialog_color(Point.new(*@locs['Probe fert'])).blue <= 200
  end

  def add_water
    dialog_click(Point.new(*@locs['Water']))
  end
  def add_fert
    dialog_click(Point.new(*@locs['Fert']))
  end


  # Window must be visible, holding lock.  
  def crop_done
    text = read_text
    if text.include?('Ready to') || text.include?('Danger')
      dialog_click(Point.new(*@locs['Harvest']))
      unpin
      log "crop was done"
      return true
    else
      return false
    end
  end


  def fill_water
    # Max of four water adds.
    4.times do
      add_water
      # Let window update? 
      sleep WINDOW_UPDATE_DELAY
      break unless needs_water
    end
  end
  def fill_fert
    # Max of four fert adds.
    4.times do
      add_fert
      # Let window update? 
      sleep WINDOW_UPDATE_DELAY
      break unless needs_fert
    end
  end

  def tend(start_lock, ticks, fert_p)
    with_robot_lock do
      delay_sec = 0.001
      2.times {dialog_click(Point.new(*@locs['Water']), delay_sec)}
      if fert_p
        2.times {dialog_click(Point.new(*@locs['Fert']), delay_sec)}
      end
    end

    # Just pass through the lock before starting.
    start_lock.synchronize {}

    ticks.times do
      # Wait till it needs water.
      loop do
        tick_done = false
        with_robot_lock do
          refresh

          # If it's ready for harvest, or if in danger, just havest,
          # and unpin, and we're done.
          if crop_done
            log 'Crop done'
            return
          end
          
          if needs_water
            tick_done = true
            fill_water
            if needs_fert && fert_p
              fill_fert
            end
          end
        end
        break if tick_done
        sleep 5
      end
      # Should be a while untl the next tick.
      sleep 10
    end

    # Wait a final time.
    loop do
      with_robot_lock do
	refresh
        if needs_water
          dialog_click(Point.new(*@locs['Harvest']))
          unpin
          log "done final tick"
          return 
        end
      end
      sleep 5
    end
    log "Mystery exit"
  end
  def log(msg)
    puts "Bed #{@index}: #{msg}" if @logging
  end
end
Action.add_action(Barley.new)
