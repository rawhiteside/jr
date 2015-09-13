require 'action'
require 'jmonitor'

class JugCount
  attr_reader :count
  attr_reader :lock
  def initialize(num)
    @count = @max = num
    @lock = JMonitor.new
  end

  def used_one
    @lock.synchronize {@count -= 1}
  end

  def used(n)
    @lock.synchronize {@count -= n}
  end

  def refill
    @lock.synchronize {@count = @max}
  end

end

class InfiniteJugs < JugCount
  def initialize
    super(99999)
  end
  def used_one
  end
end

class Vegetable < ARobot

  # water_win - A window with a "fill" button (for aqueducts). May be nil, so we fill from the icon.
  def initialize(loc, first_point, last_point, width = 1, wdir = [0,0], 
		 jc = InfiniteJugs.new, water_win = nil)
    super()
    @location = loc
    @water_win = water_win
    @jug_count = jc
    @first = first_point
    @last = last_point
    @state = 0
    @width = width
    @last_count = 0
    @probes = build_probes(first_point, last_point, width, wdir)
    @probe_bounds = rectangle_for_points(@probes)
  end

  def read_pixel_block
    screen_rectangle(@probe_bounds.x, 
		     @probe_bounds.y, 
		     @probe_bounds.width, 
		     @probe_bounds.height)
  end

  # returns a hash with keys: x, y, width, height.
  # it's the bounding box for the provided array of [x,y]
  def rectangle_for_points(points)
    xmin = ymin = 9999999
    xmax = ymax = -1
    points.each do |xy|
      xmin = [xmin, xy[0]].min
      ymin = [ymin, xy[1]].min
      xmax = [xmax, xy[0]].max
      ymax = [ymax, xy[1]].max
    end
    # Sometimes we look around the probe point at +- 1
    h = Rectangle.new(xmin - 1, ymin - 1,
		      xmax - xmin + 3,
		      ymax - ymin + 3)
    return h
  end

  def build_probes(first_point, last_point, width = 1, wdir = [0, 0])
    
    delta_x = (last_point[0] - first_point[0])
    delta_y = (last_point[1] - first_point[1])
    num_probes = [delta_x.abs, delta_y.abs].max
    probes = []
    @width = width
    step_x = delta_x / num_probes.to_f
    step_y = delta_y / num_probes.to_f
    half_width = width / 2
    num_probes.times {|i|
      xbase = first_point[0] + (step_x * i).to_i
      ybase = first_point[1] + (step_y * i).to_i
      width.times {|w|
	x = xbase + (w - half_width) * wdir[0]
	y = ybase + (w - half_width) * wdir[1]
	probes << [x, y]
      }
    }
    # So we search from the outside in.

    return probes.reverse!
  end

  # Search along the @probes path for a green pixel.
  # we do it twice, to make sure that it didn't grow during our 
  # sweep.  Can happen on slow boxes.
  def last_green(pb)
    prev = last_green_1(pb)
    loop do
      curr = last_green_1(pb)
      return curr if curr == prev
      prev = curr
    end
    
  end

  def last_green_1(pb)
    @probes.each_index do |i|
      xy = @probes[i]
      if vegetable?(pb, xy[0], xy[1])
	return i
      end
    end
    return @probes.size - 1
  end

  # Works for green things.
  def vegetable?(pb, x, y)
    green?(pb, x, y) &&
      green?(pb, x - 1, y) && green?(pb, x + 1, y) &&
      green?(pb, x, y-1) && green?(pb, x, y+1)
  end

  def green?(pb, x, y)
    r = g = b = 0
    with_robot_lock {
      @jug_count.lock.synchronize {
	color = pb.color_from_screen(x, y)
	r, g, b = color.get_red, color.get_green, color.get_blue
      }
    }
    ((g - 25) > r && (g - 25) > b)
  end

  def count_changed(current)
    (current - @last_count).abs > (3 * @width)
  end

  def refill
    with_robot_lock do
      @jug_count.lock.synchronize do
	if @water_win.nil?
	  rclick_at(341, 86)
	  HowMuch.new(:max)
	else
	  @water_win.refresh
	  sleep_sec(0.2)
	  @water_win.click_on("Fill")
	end
	@jug_count.refill
	sleep_sec 0.4
      end
    end
  end

  def water(xy)
    unless PinnableWindow.from_screen_click(Point.new(xy[0], xy[1])).click_on('Water')
      raise "Failed to water"
    end

    unless @jug_count.nil?
      @jug_count.used_one
      refill if @jug_count.count < 1
    end
  end

  # returns whether-planted.
  def grow
    case @state
    when 0 then
      #
      # Needs to be planted
      BuildMenu.new.plant(@location)
      sleep_sec 0.8
      # Water the newly-planted veggie.
      @last_count = last_green(read_pixel_block)
      xy = @probes[@last_count]
      water(xy)
      @state = 1
    when 1, 2, 3 then
      #
      # Needs water.
      current_count = last_green(read_pixel_block)
      if count_changed(current_count)
	xy = @probes[current_count]
	water(xy)
	@state += 1
	@last_count = current_count
      end
    when 4 then
      #
      # Harvest
      current_count = last_green(read_pixel_block)
      if count_changed(current_count)
	xy = @probes[current_count]
	with_robot_lock do
	  @jug_count.lock.synchronize do
	    unless PinnableWindow.from_screen_click(Point.new(xy[0], xy[1])).click_on('Harvest')
	      raise "Failed to harvest"
	    end
	  end
	end
	@last_count = current_count
	@state += 1
      end
    when 5 then
      # Waiting for harvested plant to vanish
      current_count = last_green(read_pixel_block)
      if count_changed(current_count)
	@last_count = current_count
	@state = 0
      end
    end
  end

end

class Cabbage < Vegetable
  def green?(pb, x, y)
    c = pb.color_from_screen(x, y)
    r, g, b = c.get_red, c.get_green, c.get_blue
    ((g - 10) > r && (g - 10) > b)
  end
end


class VeggieAction < Action
  def initialize(n, g)
    super(n, g)
  end

  def get_veggie_params(parent, t)
    # Coords are relative to your head in cart view.
    gadgets = [
      {:type => :point, :label => 'Drag onto your head', :name => 'head'},
      {:type => :number, :label => 'How many jugs?', :name => 'jugs'},
      {:type => :point, :label => 'Aqueduct menu (optional)', :name => 'fill'},
    ]
    return UserIO.prompt(parent, t, t, gadgets)
  end

  # For making these resolution-independent.

  # Original measurements were on a particular display, where the
  # person's head was at 639, 511.
  #
  # This method transforms those coords to a new coord system where the 
  # head is at +head+
  def back_compatible(head, point)
    [
      point[0] - 639 + head[0],
      point[1] - 511 + head[1],
    ]
  end

  def head_rel(head, point)
    [
      point[0] + head[0],
      point[1] + head[1],
    ]
  end
end

class Cabbages < VeggieAction
  def initialize()
    super("Grow Cabbages", 'Plants')
  end


  def setup(parent)
    @vals = get_veggie_params(parent, 'cabbages')
  end

  def act
    jc = JugCount.new(@vals['jugs'].to_i)
    origin = [ @vals['head.x'].to_i, @vals['head.y'].to_i ]

    v1 = Cabbage.new([:n, :n, :R, :R, :R],
		     back_compatible([656, 464], origin),
		     back_compatible([732, 321], origin),
		     5, [1,0], jc)
    v2 = Cabbage.new([:s, :s, :L, :L, :L],
		     back_compatible([620, 563], origin),
		     back_compatible([560, 711], origin),
		     5, [1,0], jc)
    loop do
      sleep_sec(1)
      v1.grow
      v2.grow
    end
  end
end
# Action.add_action(Cabbages.new)

class Leeks < VeggieAction
  def initialize()
    super("Grow Leeks", 'Plants')
  end

  def setup(parent)
    @vals = get_veggie_params(parent, 'leeks')
  end

  def act

    water_window = PinnableWindow.from_point(point_from_hash(@vals, 'fill'))

    jc = JugCount.new(@vals['jugs'].to_i)
    origin = [ @vals['head.x'].to_i, @vals['head.y'].to_i ]
    leeks = [
      Vegetable.new([:n, :n],
		    back_compatible([643, 475], origin),
		    back_compatible([632, 280], origin),
		    8, [1, 0], jc, water_window),
      Vegetable.new([:e, :e, :R, :R, :R],
		    back_compatible([673, 515], origin),
		    back_compatible([900, 498], origin),
		    8, [0, 1], jc, water_window),
      Vegetable.new([:s, :s, :R, :R, :R, :R, :R, :R],
		    back_compatible([636, 553], origin),
		    back_compatible([646, 800], origin),
		    8, [1,0], jc, water_window),
      Vegetable.new([:w, :w, :L, :L, :L],
		    back_compatible([597, 501], origin),
		    back_compatible([380, 516], origin),
		    8, [0, 1], jc, water_window),
    ]
    loop do
      sleep_sec(1)
      leeks.each do |leek|
	leek.grow
      end
    end
  end
end
# Action.add_action(Leeks.new)

class Carrot < Vegetable
  def vegetable?(pb, x, y)
    orange?(pb, x, y) && 
      orange?(pb, x-1, y) && orange?(pb, x+1, y) && 
      orange?(pb, x, y-1) && orange?(pb, x, y+1)
  end

  def orange?(pb, x, y)
    c = pb.color_from_screen(x, y)
    r, g, b = c.get_red, c.get_green, c.get_blue
    b < 100 && g > 100  && g < 200 && r > 190
  end
end

class Carrots < VeggieAction
  def initialize()
    super("Grow Carrots", 'Plants')
  end

  def setup(parent)
    @vals = get_veggie_params(parent, 'carrots')
  end

  def act
    jc = JugCount.new(@vals['jugs'].to_i)
    origin = [ @vals['head.x'].to_i, @vals['head.y'].to_i ]


    carrots = [
      Carrot.new([:n, :n, :R, :R, :R, :R, :R],
		 back_compatible([640, 475], origin),
		 back_compatible([646, 338], origin),
		 20, [1, 0], jc),
      Carrot.new([:e, :e, :L, :L, :L, :L],
		 back_compatible([680, 510], origin),
		 back_compatible([807, 529], origin),
		 20, [0, 1], jc),
      Carrot.new([:s, :s, :L],
		 back_compatible([638, 564], origin),
		 back_compatible([629, 689], origin),
		 20, [1,0], jc),
      Carrot.new([:w, :w, :R, :R],
		 back_compatible([607, 510], origin),
		 back_compatible([467, 514], origin),
		 20, [0, 1], jc),
    ]
    loop do
      sleep_sec(1)
      carrots.each do |carrot|
	carrot.grow
      end
    end
  end
end
# Action.add_action(Carrots.new)

class Garlic < VeggieAction
  def initialize()
    super("Grow Garlic", 'Plants')
  end

  def setup(parent)
    @vals = get_veggie_params(parent, 'garlic')
  end

  def act
    jc = JugCount.new(@vals['jugs'].to_i)
    origin = [ @vals['head.x'].to_i, @vals['head.y'].to_i ]

    garlics = [
      Vegetable.new([:n, :n, :R],
		    head_rel([-14, -67], origin),
		    head_rel([-45, -232], origin),
		    5, [1, 0], jc),
      Vegetable.new([:e, :e, :R, :R, :R, :R],
		    head_rel([63, 3], origin),
		    head_rel([222, -30], origin),
		    5, [0, 1], jc),
      Vegetable.new([:s, :s, :L, :L, :L, :L, :L ],
		    head_rel([2, 83], origin),
		    head_rel([36, 248], origin),
		    5, [1,0], jc),
      Vegetable.new([:w, :w, :L, :L],
		    head_rel([-77, 15], origin),
		    head_rel([-238, 47], origin),
		    5, [0, 1], jc),
    ]
    loop do
      sleep_sec(1)
      garlics.each do |garlic|
	garlic.grow
      end
    end
  end
end
#Action.add_action(Garlic.new)
