require 'action'

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
    return UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def gather(origin, width, height)
    sleep 0.2
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
	      sleep 0.1
	    end
	  end
	end
      end
    end
  end

  def old_gather(origin, width, height)
    sleep 0.2
    pixels = screen_rectangle(origin[0], origin[1], width, height)
    height.times do |y|
      next if y == 0 || y == height - 1
      width.times do |x|
	next if x == 0 || x == width - 1
	if yellow?(pixels.color(x, y))
	  screen_x, screen_y  = pixels.to_screen(x, y)
	  rclick_at(screen_x, screen_y)
	  sleep 0.1
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
    HowMuch.max if @stash_window.click_on('Stash/Papyrus')
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
    HowMuch.max if @stash_window.click_on('Stash/Papyrus')
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

class PapyTanks < GridAction
  def initialize
    super('Papy Tanks', 'Buildings')
  end
  
  def get_gadgets
    super  + [
      {:type => :number, :label => 'How many seeds?', :name => 'seed_count',},
    ]
  end
  def start_pass(index)
    @piler = Piler.new
    @windows = []
    @seed_count = @user_vals['seed_count'].to_i
  end

  def act_at(ginfo)

    win = PinnableWindow.from_screen_click(ginfo['x'], ginfo['y'])
    win.pin
    text = win.read_text
    if text.include?('Harvest') || text.include?('Plant')
      @piler.pile(win)
      @windows << win
    else
      win.unpin
    end
  end
  
  def end_pass(index)
    @piler.swap
    @windows.each do |win|
      win.refresh
      win.click_on('Harvest')
      @piler.pile(win)
      sleep 0.3
    end
    @windows.each do |win|
      win.refresh
      win.click_on('Plant')
      HowMuch.amount(@seed_count)
      win.unpin
      sleep 0.5
    end
  end

end
  
Action.add_action(PapyTanks.new)
