require 'action'

class PlantPapy < Action
  def initialize
    super('Plant Papyrus', 'Gather')
  end

  def plant
    rclick_at(31,44)
  end

  def run_and_plant_once
    # Plant every plant_sep coords
    plant_delay = 8
    plant_sep = 3
    walker = Walker.new
    puts 'starting'
    ChatLineWindow.new.minimize
    # 
    # Go to starting point.
    max_y = -2120
    min_y = -2150
    x = 926
    walker.walk_to([x, min_y])
    p [x, min_y]
    plant
    y = min_y
    puts "first part"
    loop do
      y += plant_sep
      break if y > max_y
      p [x, y]
      walker.walk_to([x, y])
      sleep_sec plant_delay
      plant
    end
    walker.walk_to([x, min_y])
    # return
    # Now, do the southern part, across the bridge. 
    pts = [
      [927, -2176],
      [932, -2178],
      [945, -2178],
      [944, -2182],
      [943, -2186],
      [943, -2190],
      [943, -2195],
      [942, -2200],
      [942, -2204],
    ]
    puts 'walking souther part. '
    pts.each do |p|
      walker.walk_to(p)
      sleep_sec plant_delay
      plant
    end
    walk_back_pts = [
      [924, -2185],
      [924, -2153],
      [x, min_y],
    ]
    walk_back_pts.each {|p| walker.walk_to(p)}
  end

  def act
    loop do
      run_and_plant_once
    end
  end
end

Action.add_action(PlantPapy.new)

class HarvestPapy < Action
  def initialize(name, group)
    super(name, group)
  end

  def get_uvals(parent)
    # Coords are relative to your head in cart view.
    gadgets = [
      {:type => :point, :label => 'UL Corner of gather region',
	:name => 'ul'},
      {:type => :point, :label => 'LR Corner of gather region',
	:name => 'lr'},
      {:type => :point, :label => 'Drag to the pinned WH menu.',
	:name => 'stash'},
    ]
    return UserIO.prompt(parent, 'papyrus', 'papyrus', gadgets)
  end

  def gather(origin, width, height)
    sleep_sec 0.2
    2.times do
      pixels = screen_rectangle(origin[0], origin[1], width, height)
      height.times do |y|
	next if y == 0 || y == height - 1
	width.times do |x|
	  next if x == 0 || x == width - 1
	  if yellow?(pixels.color(x, y))
	    screen_x, screen_y  = pixels.to_screen(x, y)
	    if yellow?(get_color(screen_x, screen_y))
	      rclick_at(screen_x, screen_y)
	      sleep_sec 0.1
	    end
	  end
	end
      end
    end
  end

  def old_gather(origin, width, height)
    sleep_sec 0.2
    pixels = screen_rectangle(origin[0], origin[1], width, height)
    height.times do |y|
      next if y == 0 || y == height - 1
      width.times do |x|
	next if x == 0 || x == width - 1
	if yellow?(pixels.color(x, y))
	  screen_x, screen_y  = pixels.to_screen(x, y)
	  rclick_at(screen_x, screen_y)
	  sleep_sec 0.1
	  pixels = screen_rectangle(origin[0], origin[1], width, height)
	end
      end
    end
  end

  def yellow?(color)
    r, g, b = color.red, color.green, color.blue 
    r > 200 && g > 200 && b < 100
  end

  def setup(parent)
    @vals = get_uvals(parent)
  end

  def act
    first_time = true
    origin = [@vals['ul.x'].to_i, @vals['ul.y'].to_i]
    width = @vals['lr.x'].to_i  - @vals['ul.x'].to_i 
    height = @vals['lr.y'].to_i  - @vals['ul.y'].to_i
    @stash_window = PinnableWindow.from_point(point_from_hash(@vals, 'stash'))

    walker = Walker.new
    path = get_path.reverse
    walker.walk_back_and_forth(path, 99999) do |param|
      next if param == :skip
      gather(origin, width, height)
      if param == :stash
	if first_time
	  first_time = false
	else
	  stash
	end
      end
    end
  end
end

class HarvestPapyEast < HarvestPapy
  def initialize
    super('Harvest Papy, East side', 'Gather')
  end

  # Go to the warehouse and stash.
  def stash
    stash_loc = [994, -2266]
    Walker.new.walk_to(stash_loc)
    HowMuch.new(:max) if @stash_window.click_on('Stash/Papyrus')
    @stash_window.click_on('Stash/Insect/Stash All')
  end
  
  def get_path
    [
      [959, -2134,],
      [959, -2138,],
      [959, -2142,],
      [959, -2146,],
      [959, -2150,],
      [962, -2154,],
      [966, -2165,],
      [968, -2168,],
      [971, -2172,],
      [973, -2176,],
      [974, -2178,],
      [974, -2182,],
      [975, -2186,],
      [975, -2190,],
      [976, -2194,],
      [976, -2198,],
      [976, -2202,],
      [977, -2206,],
      [977, -2210,],
      [978, -2214,],
      [979, -2218,],
      [982, -2222,],
      [985, -2226,],
      [988, -2230,],
      [990, -2234,],
      [991, -2238,],
      [992, -2242,],
      [993, -2246, :stash],
    ]
  end
end
Action.add_action(HarvestPapyEast.new)

class HarvestPapyWest < HarvestPapy
  def initialize
    super('Harvest Papy, West side', 'Gather')
  end


  # Go to the warehouse and stash.
  def stash
    HowMuch.new(:max) if @stash_window.click_on('Stash/Papyrus')
    @stash_window.click_on('Stash/Insect/Stash All')
  end

  def get_path
    [
      [925, -2125],
      [925, -2129],
      [925, -2133],
      [925, -2137],
      [925, -2140],
      [925, -2144],
      [925, -2148],
      [925, -2152],
      [925, -2156],
      [927, -2164],
      [928, -2166],
      [927, -2168],
      [927, -2171],
      [927, -2175],
      [931, -2179],
      [935, -2179],
      [935, -2172],
      [939, -2169],
      [942, -2169],
      [945, -2169],
      [945, -2171],
      [945, -2175],
      [945, -2179],
      [943, -2180],
      [943, -2184],
      [943, -2188],
      [943, -2191],
      [943, -2195],
      [942, -2197],
      [942, -2201],
      [942, -2205],
      [942, -2209],
      [944, -2211],
      [944, -2215],
      [944, -2219],
      [944, -2222],
      [944, -2225],
      [944, -2228],
      [946, -2231],
      [946, -2235],
      [949, -2238],
      [950, -2241],
      [956, -2253, :skip],
      [965, -2253, :skip],
      [966, -2241],
      [966, -2244],
      [964, -2266, :stash],
    ]
  end
end

Action.add_action(HarvestPapyWest.new)
