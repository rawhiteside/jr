require 'action.rb'
require 'window'
require 'pixel_block'

class Onions < Action
  def initialize(name = "Grow onions", category = 'Plants')
    super(name, category)
  end

  # Compute the various locations we need
  def build_recipe
    @build_locations = []
    @pop_locations = []
    @pin_locations = []

    # Coords are relative to your "head" in Cart view.
    recipe_for_row_at_spot([:n, :n], [-59, -43], 176)
    recipe_for_row_at_spot([:se, :L, :L], [40, 98], 261)
    recipe_for_row_at_spot([:sw, :L, :L], [-87, 45], 346)
  end

  def recipe_for_row_at_spot(build_pos, first_pop_xy, y_pin)
    revolve = [ [], [:r], [:r, :r], [:r, :r, :r],
      [:R, :l, :l, ], [:R, :l,],
      [:R], [:R, :r], [:R, :r, :r], [:R, :r, :r, :r],
      [:R, :R, :l, :l], [:R, :R, :l]
    ]
    11.times do |i|
      @build_locations << (build_pos + revolve[i])
      @pop_locations << (i == 0 ? first_pop_xy : nil)
      @pin_locations << [107*i, y_pin]
    end
  end

  def stop
    @threads.each {|t| t.kill} if @threads
    super
  end

  def get_onion_params(parent)
    # Coords are relative to your head in cart view.
    gadgets = [
      {:type => :point, :label => 'Drag onto your head', :name => 'head'},
      {:type => :point, :label => 'Aqueduct menu (optional)', :name => 'fill'},
    ]
    return UserIO.prompt(parent, 'onions', 'onions', gadgets)
  end

  # Transform to the head at the origin.
  def head_rel(head, point)
    [
     point[0] + head[0],
     point[1] + head[1],
    ]
  end

  def setup(parent)
    @vals = get_onion_params(parent)
  end

  def act
    build_recipe
    head = [@vals['head.x'].to_i, @vals['head.y'].to_i]
    water_window = PinnableWindow.from_point(point_from_hash(@vals, 'fill'))

    # Transform to resolution-independent coords.
    @pop_locations.collect!{|p|
      p.nil? ? nil : head_rel(head, p)
    }

    loop do
      @threads = []
      pop_at = @pop_locations[0]
      builder = BuildMenu.new
      @build_locations.each_index do |i|
	build_at = @build_locations[i]
	#
	# Take a non-nil value from the pop array.  Otherwise, 
	# just use the previons pop location.
	pop_at = @pop_locations[i] || pop_at
	pin_at = Point.new(@pin_locations[i][0], @pin_locations[i][1])
	# 
	# Snapshot before planting
	size = 25
	size = 40 if @pop_locations[i].nil?
	w = PixelBlockWatcher.new(pop_at[0], pop_at[1], size, size, 1)
	builder.plant(build_at)
	#
	# ... and this pop_at gets used next time through the
	# loop as the starting search location.
	p = []
	until p[0] && p[1]
	  p = w.find_surrounded_green_change
	  sleep_sec 0.3
	end
	pop_at = p
	dialog = nil
	with_robot_lock {
	  dialog = PinnableWindow.from_screen_click(Point.new(pop_at[0], pop_at[1]))
	  dialog = OnionWindow.new(dialog.get_rect)
	}
	dialog.pin.drag_to(pin_at)
	@threads << ControllableThread.new {OnionTender.new(dialog).tend }
      end

      puts "Waiting for tenders..."
      @threads.each {|t| t.join }
      fill_jugs(water_window)
    end
  end

  def fill_jugs(win)
    with_robot_lock {
      if win.nil?
	rclick_at(341, 86)
	HowMuch.new(:max)
      else
	win.refresh
	sleep_sec(0.2)
	win.click_on("Fill")
      end
    }
    sleep_sec 6
  end

end



class OnionWindow < PinnableWindow
  def initialize(xy)
    super(xy)
    # to see if we're done.
    @probe = [87, 16]
    @buttony = 50
  end

  def water_or_harvest
    refresh
    x = rect.width/2
    y = @buttony
    dialog_click(Point.new(x, y))

    self
  end

  def done?
    refresh
    dialog_pixel(Point.new(@probe[0],@probe[1])) != 0
  end
end

class OnionTender < ARobot
  # Coordinates are for the x-center of the pinned dialog, and
  # the y-top.
  def initialize(dialog, first_delay = 30)
    super()
    @dialog = dialog
    # Extras at the end.  Maybe it'll let us recover from server lag
    @delays = [first_delay, 25, 28, 28, 28, # harvest
      28, 28, 28, 28, 28, 28, 28]  # Extra attempts.
  end

  def tend
    count = 0
    @delays.each do |d|
      count += 1
      # At the end, the harvest check takes a chunk of time
      if count >= 6
	sleep_sec d - 5
      else
	sleep_sec d
      end
      @dialog.water_or_harvest
      if count >= 5
	# check to see if we're done.
	sleep_sec 5
	if @dialog.done?
	  with_robot_lock do
	    @dialog.refresh
	    @dialog.unpin
	  end
	  return
	end
      end
    end
  end
end
Action.add_action(Onions.new)

