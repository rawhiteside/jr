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
      {:type => :number, :label => 'How many passes?', :name => 'count'},
      {:type => :number, :label => 'Rows in the field?', :name => 'rows'},
      {:type => :number, :label => 'Cols in teh field?', :name => 'cols'},
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
    count = @vals['count'].to_i
    rows = @vals['rows'].to_i
    cols = @vals['cols'].to_i
    warehouse_window = PinnableWindow.from_point(point_from_hash(@vals, 'wh-win'))
    @plant_win = PinnableWindow.from_point(point_from_hash(@vals, 'plant-win'))

    wh_loc = WorldLocUtils.parse_world_location(@vals['wh-loc'])
    @grow_loc = WorldLocUtils.parse_world_location(@vals['grow-loc'])
    water_loc = WorldLocUtils.parse_world_location(@vals['water-loc'])

    loop do
      count.times { grow_one_field(rows, cols) }

      # Now, refill everything for another round

      # Refill the jugs.
      @walker.walk_to(water_loc)
      Icons.refill
      # Stash the barley
      @walker.walk_to(wh_loc)
      warehouse_window.click_on('Stash/Barley')
      HowMuch.max
      # take enough back to plant (plus a buffer)
      if warehouse_window.click_on('Take/Barley')
	HowMuch.amount(15 * count + 5)
      end
      sleep 0.1
      # Take 270 grain fert
      #if warehouse_window.click_on('Take/Grain')
      #HowMuch.amount(90 * count)
      #end

    end
  end


  def pop_locations
    {
      [:right] => [@center_x + 50, @center_y + 50],
      [:down] => [@center_x + 50, @center_y + 50],
      [:left] => [@center_x - 50, @center_y + 30],
      [:up] => [@center_x - 50, @center_y + 30],
    }
  end

  def plant_and_pin(pop_coords)

    # Dunno why, but sometimes the plant fails.  Doesn't happen with
    # other veggies...  Give an extra delay.
    w = nil
    with_robot_lock {
      puts "plant failed" unless @plant_win.click_on("Plant")
      sleep 0.1
      w = PinnableWindow.from_screen_click(Point.new(pop_coords[0], pop_coords[1]))
      w = BarleyWindow.new(w.get_rect)
    }
    w.pin
    return w
  end

  def step_patterns(rows, cols)
    ncols = cols - 1
    nrows = rows - 1
    steps = [:right] * nrows
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

  def grow_one_field(rows, cols)
    #
    check_for_pause
    @walker.walk_to(@grow_loc)
    @cascader = Cascader.new
    start_lock = JMonitor.new
    prev_patt = [:right]
    # Keep tending from starting while we plant
    start_lock.synchronize do
      step_patterns(rows, cols).each do |patt|
        w = plant_and_pin(pop = @pop_for_step[prev_patt])
        @cascader.stage(w)
        start_worker_thread do
	  w.tend(start_lock)
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
  def initialize(g)
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

  def needs_water
      color = dialog_color(Point.new(*@locs['Probe water']))
      r, g, b = color.red, color.green, color.blue
      return b <= 200
  end

  def try_to_water
    done = false
    # Sometimes clicks miss.
    # Does this help?
    delay_sec = 0.01

    with_robot_lock do
      refresh
      if needs_water
        while needs_water
	  dialog_click(Point.new(*@locs['Water']), delay_sec)
          sleep delay_sec
        end
        #	dialog_click(Point.new(*@locs['Fert']), delay_sec)
	done = true
      else
	done = false
      end
    end
    return done 
  end

  def tend(start_lock)
    with_robot_lock do
      # Sometimes misses.
      delay_sec = 0.01
      dialog_click(Point.new(*@locs['Water']), delay_sec)
      dialog_click(Point.new(*@locs['Water']), delay_sec)
#      # Sometimes misses.
#      mm(to_screen_coords(Point.new(*@locs['Fert'])), delay_sec)
#      dialog_click(Point.new(*@locs['Fert']), delay_sec)
#      dialog_click(Point.new(*@locs['Fert']), delay_sec)
    end

    # Just pass through the lock before starting.
    start_lock.synchronize {}

    2.times do
      loop do
	break if try_to_water
	sleep 10
      end
    end
    # Wait a final time.
    loop do
      done = false
      with_robot_lock do
	refresh
        if needs_water
          done = true
          dialog_click(Point.new(*@locs['Harvest']))
          unpin
        end
      end
      break if done
      sleep 5
    end

    return nil
  end
end
Action.add_action(Barley.new)
