require 'action.rb'
require 'window'
require 'pixel_block'

class Peppers < Action
  def initialize
    super("Grow peppers", 'Plants')
  end

  # Compute the various locations we need
  def build_recipe(head)
    @build_locations = []
    @pop_locations = []

    # Coords are relative to your "head" in Cart view.
    recipe_for_row_at_spot([:n, :n], [head[0], head[1] - 78])
    recipe_for_row_at_spot([:e, :e], [head[0] + 75, head[1]])
    recipe_for_row_at_spot([:s, :s], [head[0], head[1] + 78])
  end

  def recipe_for_row_at_spot(build_pos, first_pop_xy)

    revolve = [
      [], [:L], [:R], [:L]*2, [:R]*2, [:L]*3,
    ]
    revolve.size.times do |i|
      @build_locations << (build_pos + revolve[i])
      @pop_locations << (i == 0 ? first_pop_xy : nil)
    end
  end

  def stop
    @threads.each {|t| t.kill} if @threads
    super
  end

  def get_pepper_params(parent)
    # Coords are relative to your head in cart view.
    gadgets = [
      {:type => :point, :label => 'Drag onto your head', :name => 'head'},
      {:type => :number, :label => 'Jug count', :name => 'jugs'},
      {:type => :text, :label => 'Space-separated water counts', :name => 'water-recipe'},
    ]
    return UserIO.prompt(parent, 'peppers', 'peppers', gadgets)
  end

  def setup(parent)
    @vals = get_pepper_params(parent)
  end

  def act
    head = [@vals['head.x'].to_i, @vals['head.y'].to_i]
    @jugs = JugCount.new(@vals['jugs'].to_i)
    build_recipe(head)
    water_recipe = @vals['water-recipe'].split(' ')
    plant_win = PinnableWindow.from_point(Point.new(44,44))

    loop do
      ControllableThread.check_for_pause

      tiler = Tiler.new(0, 176, 0.45)
      @threads = []
      pop_at = @pop_locations[0]
      builder = BuildMenu.new
      @build_locations.each_index do |i|
	build_at = @build_locations[i]
	#
	# Take a non-nil value from the pop array.  Otherwise, 
	# just use the previons pop location.
	pop_at = @pop_locations[i] || pop_at
	# 
	# Snapshot before planting
	size = 40
	# size = 60 if @pop_locations[i].nil?
	watcher = PixelBlockWatcher.new(pop_at[0], pop_at[1], size, size, 1)
	plant_win.refresh
	builder.plant(build_at)
	#
	# ... and this pop_at gets used next time through the
	# loop as the starting search location.
	pt = []
	until pt[0] && pt[1]
	  pt = watcher.find_surrounded_green_change(60)
	  sleep_sec 0.3
	end
	pop_at = pt
	dialog = nil
	pepper_win = nil
	with_robot_lock {
	  pepper_win = PinnableWindow.from_screen_click(Point.new(pop_at[0], pop_at[1])).pin
	  tiler.tile(pepper_win)
	}
	tender = PepperTender.new(pepper_win, water_recipe.dup, @jugs)
	@threads << ControllableThread.new {tender.tend }
      end
      @threads.each {|t| t.join }
    end
  end
end


class PepperTender < ARobot
  INITIAL_DELAY = 32.0
  INTER_WATER_DELAY = 25
  # Coordinates are for the x-center of the pinned dialog, and
  # the y-top.
  def initialize(dialog, recipe, jugs)
    @jugs = jugs
    @dialog = dialog
    @recipe = recipe.dup
  end

  def tend
    recipe = @recipe.dup
    water_count = nil
    sleep_sec INITIAL_DELAY
    loop do
      water_count = recipe.shift.to_i if recipe.size > 0
      harvested = false
      
      with_robot_lock do
	@dialog.refresh(:tc)
	harvested = true
	break if @dialog.click_on("Harvest")
	harvested = false

	refill if @jugs.count <= water_count
	@dialog.click_on("Use #{water_count}")
	@jugs.used(water_count)
      end
      break if harvested
      sleep_sec INTER_WATER_DELAY
    end

    with_robot_lock do
      @dialog.refresh
      @dialog.unpin
    end
  end

  def refill
    with_robot_lock do
      @jugs.lock.synchronize do 
	rclick_at(341, 86)
	HowMuch.new(:max)
	@jugs.refill
	sleep_sec 0.05
      end
    end
  end
end
Action.add_action(Peppers.new)
