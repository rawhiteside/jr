require 'action'
require 'window'
require 'walker'
require 'image_utils'
require 'icons'

class Barley < Action
  # 
  # World coordinates at which you shoudl plant the first bed
  START_PLANT_LOC = [-415, -6738]
  # 
  # World coordinates that get you access to water, and
  # within reach of the warehouse.
  WH_LOC = [-406, -6738]

  def initialize
    super('Barley', 'Plants')
    @plant = [25, 45]
    @pop = [670, 485]
    @dialogs = []
    @walker = Walker.new
  end

  def pop_locations
    {
      [:right] => [@head_x + 50, @head_y + 50],
      [:down] => [@head_x + 50, @head_y + 50],
      [:left] => [@head_x - 50, @head_y + 30],
      [:up] => [@head_x - 50, @head_y + 30],
    }
  end

  def plant_and_tile(pop_coords)

    # Dunno why, but sometimes the plant fails.  Doesn't happen with
    # other veggies...  Give an extra delay.
    w = nil
    with_robot_lock {
      mm(*@plant)
      sleep 0.05
      rclick_at(*@plant)
      mm(*pop_coords)
      sleep 0.1
      w = PinnableWindow.from_screen_click(Point.new(pop_coords[0], pop_coords[1]))
      w = BarleyWindow.new(w.get_rect)
    }
    w.pin
    @tiler.tile(w)
  end

  def step_patterns
    [
      [:right], [:right], [:right], 
      [:down],
      [:left], [:left], [:left], 
      [:down],
      [:right], [:right], [:right], 
      [],
    ]
  end

  def setup(parent)
    comps = [
      {:type => :point, :label => 'Drag onto your head', :name => 'head'},
      {:type => :point, :label => 'Drag onto pinned warehouse', :name => 'wh'},
      {:type => :label, :label => 'Each pass takes 90 water/fert'},
      {:type => :number, :label => 'How many passes?', :name => 'count'}
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, comps)
  end

  def act
    @head_x = @vals['head.x'].to_i
    @head_y = @vals['head.y'].to_i
    @pop_for_step = pop_locations
    count = @vals['count'].to_i
    wh_point = point_from_hash(@vals, 'wh')
    warehouse_window = PinnableWindow.from_point(wh_point)
    raise(Exception.new("No Warehouse at #{wh_point}!!")) unless warehouse_window

    loop do
      count.times { grow_one_field }

      # Now, refill everything for another round
      @walker.walk_to(WH_LOC)

      # Refill the jugs.
      Icons.refill
      # Stash the barley
      warehouse_window.click_on('Stash/Barley')
      HowMuch.max
      # take enough back to plant (plus a buffer)
      if warehouse_window.click_on('Take/Barley')
	HowMuch.amount(15 * count + 5)
      end
      sleep 0.1
      # Take 270 grain fert
      if warehouse_window.click_on('Take/Grain')
	HowMuch.amount(90 * count)
      end

    end
  end


  def grow_one_field
    #
    check_for_pause
    @walker.walk_to(START_PLANT_LOC)
    @tiler = Tiler.new(0, 77)
    @tiler.y_offset = 330
    start_lock = JMonitor.new
    prev_patt = [:right]
    # Keep tending from starting while we plant
    start_lock.synchronize do
      step_patterns.each do |patt|
        w = plant_and_tile(pop = @pop_for_step[prev_patt])
        start_worker_thread do
	  w.tend(start_lock)
        end
        with_robot_lock { @walker.steps(patt) }
        prev_patt = patt
      end
    end
    wait_for_worker_threads
    @walker.walk_to(START_PLANT_LOC)
  end
end


class BarleyWindow < PinnableWindow
  def initialize(g)
    super(g)
    yoff = 26
    @locs = {
      'Water' => [192, 161],
      'Fert' => [192, 180],
      'Probe water' => [170, 161],
      'Probe fert' => [172, 180],
      'Harvest' => [105, 224],
    }
    @locs.each_key {|k| @locs[k][1] -= yoff }
  end

  def try_to_water
    done = false
    # Sometimes clicks miss.
    # Does this help?
    delay_sec = 0.01

    # XXX Can't erturn a value from inside this block.
    # Figure out how to accomplish that.  Hack the Runnable, I think. 
    with_robot_lock do
      refresh
      color = dialog_color(Point.new(*@locs['Probe water']))
      r, g, b = color.red, color.green, color.blue

      if b > 200
	done = false
      else
	mm(to_screen_coords(Point.new(*@locs['Water'])), delay_sec)
	dialog_click(Point.new(*@locs['Water']), 'tc', delay_sec)
#	mm(to_screen_coords(Point.new(*@locs['Fert'])),delay_sec)
#	dialog_click(Point.new(*@locs['Fert']), 'tc', delay_sec)
	done = true
      end
    end
    return done 
  end

  def tend(start_lock)
    with_robot_lock do
      # Sometimes misses.
      delay_sec = 0.01
      mm(to_screen_coords(Point.new(*@locs['Water'])), delay_sec)
      dialog_click(Point.new(*@locs['Water']), 'tc', delay_sec)
      dialog_click(Point.new(*@locs['Water']), 'tc', delay_sec)
#      # Sometimes misses.
#      mm(to_screen_coords(Point.new(*@locs['Fert'])), delay_sec)
#      dialog_click(Point.new(*@locs['Fert']), delay_sec)
#      dialog_click(Point.new(*@locs['Fert']), delay_sec)
    end

    # Just pass through the lock before starting.
    start_lock.synchronize {}

    4.times do
      loop do
	break if try_to_water
	sleep 5
      end
    end
    # Wait a final time.
    loop do
      done = false
      with_robot_lock do
	refresh
	b = dialog_color(Point.new(*@locs['Probe water'])).blue
	if b < 200
	  done = true
	end
      end
      break if done
      sleep 3
    end

    with_robot_lock do
      dialog_click(Point.new(*@locs['Harvest']))

      # OK, so barley windows are weird.  After harvest, they get
      # smaller both vertically and horizontally.
      # we have to re-acquire a window to un pin it.
      sleep 0.2
      rectangle = get_rect
      point = Point.new(rect.x, rect.y + rect.height/2)
      PinnableWindow.from_point(point).unpin
    end
    return nil
  end
end
Action.add_action(Barley.new)
