require 'action'
require 'actions/abstract_mine'
require 'bounds'

class SandMine < AbstractMine
  def initialize
    super('Mine sand', 'Misc')
  end

  def setup(parent)
    gadgets = [
      {:type => :frame, :label => 'Ore field', :name => 'field',
	:gadgets =>
	[
	  {:type => :point, :label => 'UL corner', :name => 'ul'},
	  {:type => :point, :label => 'LR corner', :name => 'lr'},
	]
      },
      {:type => :frame, :label => 'Height of a single stone', :name => 'stone',
	:gadgets =>
	[
	  {:type => :point, :label => 'Above a stone', :name => 'ul'},
	  {:type => :point, :label => 'Below that stone', :name => 'lr'},
	]
      },
      {:type => :frame, :label => 'Bounding box for the mine', :name => 'mine',
	:gadgets =>
	[
	  {:type => :point, :label => 'UL corner', :name => 'ul'},
	  {:type => :point, :label => 'LR corner', :name => 'lr'},
	]
      },
      {:type => :frame, :label => 'Avatar bounding box', :name => 'avatar',
	:gadgets =>
	[
	  {:type => :point, :label => 'UL corner', :name => 'ul'},
	  {:type => :point, :label => 'LR corner', :name => 'lr'},
	]
      },
      {:type => :combo, :label => 'Large gems?', :name => 'large',
	:vals => ['y', 'n']},

      {:type => :text, :label => 'Work delay(sec)', :name => 'delay',},

      {:type => :text, :label => 'Base/stone denom', :name => 'base-denom',},

      {:type => :combo, :label => 'Debug mode?', :name => 'debug',
	:vals => ['y', 'n']},
    ]
    @vals = UserIO.prompt(parent, 'sand_mine', 'Mine sand', gadgets)
  end

  def act
    ul = [@vals['field.ul.x'].to_i, @vals['field.ul.y'].to_i]
    lr = [@vals['field.lr.x'].to_i, @vals['field.lr.y'].to_i]
    bb_field = Bounds.new(ul, lr)

    mine_ul = [@vals['mine.ul.x'].to_i, @vals['mine.ul.y'].to_i]
    mine_lr = [@vals['mine.lr.x'].to_i, @vals['mine.lr.y'].to_i]
    bb_mine = Bounds.new(mine_ul, mine_lr)

    avatar_ul = [@vals['avatar.ul.x'].to_i, @vals['avatar.ul.y'].to_i]
    avatar_lr = [@vals['avatar.lr.x'].to_i, @vals['avatar.lr.y'].to_i]
    bb_avatar = Bounds.new(avatar_ul, avatar_lr)

    delta = (@vals['stone.ul.y'].to_i - @vals['stone.lr.y'].to_i).abs
    debug = @vals['debug'] == 'y'
    delay = @vals['delay'].to_f
    denom = @vals['base-denom'].to_f

    want_larges = @vals['large'] == 'y'

    w = PinnableWindow.from_point(Point.new(40, 60))
    @debug = @vals['debug'] == 'y'
    ControllableThread.check_for_pause
    loop do
      begin
	ControllableThread.check_for_pause
	scene = OreStoneScene.new(bb_field, bb_mine,
				  bb_avatar, delta, debug, denom)
	scene.stones.each {|stone| p stone}
	if debug
	  mouse_over_stones(scene.stones)
	end
	mine_stones(scene.stones, want_larges, delay)
      rescue BadWorkloadException => e
	puts 'Bad workload exception.'
	# No need for anything.  Just mine again.
      end
      sleep_sec 1 while dismiss_strange_windows
      loop do
	work_mine(w)
	sleep_sec 1
	break unless dismiss_strange_windows
	puts 'looping again in dissmis_strange'
      end
    end
  end

  def mouse_over_stones(stones)
    stones.each do |s|
      mm(s.x, s.y)
      sleep_sec 3
    end
  end

  def work_mine(w)
    puts 'working mine'
    loop do
      w.refresh
      break unless w.read_text =~ /This mine can be/
      sleep_sec 6
    end

    sleep_sec 4
    w.click_on('Work this Mine')
    sleep_sec 4
  end

  def dismiss_strange_windows
    if win = PopupWindow.find
      log_strange_window(win)
      win.dialog_click(Point.new(win.rect.width/2, win.rect.height - 20))
      sleep_sec 3
      return true
    end
    return false
  end


  def mine_stones(stones, want_larges, delay)


    ControllableThread.check_for_pause

    # OK, put them into a {color => [stone, stone, ...]} hash.
    by_color = {}
    stones.each do |stone|
      color = stone.color
      if by_color[color].nil?
	by_color[color] = [stone]
      else
	by_color[color] << stone
      end
    end

    # Now, make an array of [color, count] elements,
    # so we can sort it.
    color_count = []
    by_color.each {|color, stones| color_count << [color, stones.size]}
    color_count = color_count.sort {|a,b| b[1] <=> a[1] }
    recipe_key = color_count.collect{|elt| elt[1]}
    recipe =  (want_larges ?
	       GemMineRecipes.new.recipe(recipe_key) :
	       SmallGemMineRecipes.new.recipe(recipe_key)
	       )
    
    #
    # Now, make a new hash of {name => stone}.
    # The name will match the wiki recipe standard.
    # For example: 
    # A-1, A-2, B-1, B-2, C, D, E
    by_wiki_name = {}
    pref = 'A'
    color_count.each do |cc|
      color = cc[0]
      count = cc[1]
      stones = by_color[color]
      if count == 1
	by_wiki_name[pref] = stones[0]
      else
	stones.size.times do |i|
	  by_wiki_name[pref + '-' + (i+1).to_s] = stones[i]
	end
      end
      pref = pref.succ
    end

    if recipe
      run_recipe(recipe, by_wiki_name, delay)
      log_result('Success.')
    else
      msg = 'No recipe found for: ' + recipe_key.inspect
      log_result(msg)
    end
  end

  def log_result(msg)
    tsmsg = "#{Time.now.to_s} : #{msg}"
    File.open('mine.log', 'a') {|f| f.puts(tsmsg)}
  end

  def run_recipe(recipes, stones_by_name, delay)
    recipes.each do |recipe|
      recipe.each_index do |i|
	name = recipe[i]
	stone = stones_by_name[name]
	key = 'A'
	key = 'S' if i == (recipe.size - 1)
	send_string_at(stone.x, stone.y, key, delay)
      end
    end
  end

  def send_string_at(x, y, str, delay)
    mm(x, y)
    sleep_sec delay
    send_string(str)
    sleep_sec delay
    if win = PopupWindow.find
      log_strange_window(win)
      raise BadWorkloadException.new(win)
    end
  end

  def log_strange_window(w)
    log_result(w.read_text)
  end

end

Action.add_action(SandMine.new)


class BadWorkloadException < Exception
  attr_reader :win
  def initialize(w)
    @win = w
    super('Bad Workload')
  end
end



class GemMineRecipes
  RECIPES =
    {[2, 1, 1, 1, 1, 1] => [
      ['A-1', 'B', 'C', 'F',],
      ['A-1', 'D', 'E',],
      ['A-1', 'C', 'D', 'E',],
      ['A-1', 'B', 'F',],
      ['A-1', 'D', 'E', 'F',],
      ['A-1', 'B', 'C',],
      ['A-1', 'B', 'E', 'F',],
      ['A-2', 'C', 'D',],
      ['A-2', 'D', 'E',],
      ['A-2', 'B', 'C', 'F',],
      ['A-2', 'C', 'F',],
      ['A-2', 'B', 'E', 'D',],
      ['A-2', 'B', 'E',],
      ['A-2', 'C', 'D', 'F',],
    ],
    [2, 2, 1, 1, 1] => [
      ['C', 'D', 'E',],
      ['C', 'A-1', 'B-1',],
      ['C', 'A-1', 'B-2',],
      ['C', 'A-2', 'B-1',],
      ['C', 'A-2', 'B-2',],
      ['D', 'A-1', 'B-1',],
      ['D', 'A-1', 'B-2',],
      ['D', 'A-2', 'B-1',],
      ['D', 'A-2', 'B-2',],
      ['E', 'A-1', 'B-1',],
      ['E', 'A-1', 'B-2',],
      ['E', 'A-2', 'B-1',],
      ['E', 'A-2', 'B-2',],
      ['A-1', 'B-1', 'C', 'D', 'E',],
      ['A-2', 'B-2', 'C', 'D',],
    ],
    [3, 1, 1, 1, 1] => [
      ['A-1', 'B', 'C',],
      ['A-1', 'B', 'D',],
      ['A-1', 'B', 'E',],
      ['A-1', 'C', 'D',],
      ['A-1', 'C', 'E',],
      ['A-1', 'D', 'E',],
      ['A-2', 'B', 'C',],
      ['A-2', 'B', 'D',],
      ['A-2', 'B', 'E',],
      ['A-2', 'C', 'D',],
      ['A-2', 'C', 'E',],
      ['A-2', 'D', 'E',],
      ['A-1', 'B', 'C', 'D', 'E',],
    ],
    [2, 2, 2, 1] => [
      ['A-1', 'B-1', 'C-1',],
      ['A-2', 'B-2', 'C-2', 'D',],
      ['A-1', 'B-1', 'C-2',],
      ['A-2', 'B-2', 'C-1', 'D',],
      ['A-1', 'B-2', 'C-1',],
      ['A-2', 'B-1', 'C-2', 'D',],
      ['A-1', 'B-2', 'C-2',],
      ['A-2', 'B-1', 'C-1', 'D',],
      ['A-2', 'B-1', 'C-1',],
      ['A-1', 'B-2', 'C-2', 'D',],
      ['A-2', 'B-1', 'C-2',],
      ['A-1', 'B-2', 'C-1', 'D',],
      ['A-2', 'B-2', 'C-1',],
      ['A-1', 'B-1', 'C-2', 'D',],
    ],
    [3, 2, 1, 1] => [
      ['A-1', 'A-2', 'A-3',],
      ['A-1', 'B-1', 'C',],
      ['A-1', 'B-1', 'D',],
      ['A-1', 'B-2', 'C',],
      ['A-1', 'B-2', 'D',],
      ['A-1', 'C', 'D',],
      ['A-2', 'B-1', 'C',],
      ['A-2', 'B-1', 'D',],
      ['A-3', 'B-1', 'C',],
      ['A-3', 'B-1', 'D',],
      ['A-2', 'C', 'D',],
      ['A-1', 'B-1', 'C', 'D',],
    ],
    [4, 1, 1, 1] => [
      ['A-1', 'B', 'C',],
      ['A-1', 'B', 'D',],
      ['A-1', 'C', 'D',],
      ['A-2', 'B', 'C',],
      ['A-2', 'B', 'D',],
      ['A-2', 'C', 'D',],
      ['A-3', 'B', 'C',],
      ['A-3', 'B', 'D',],
      ['A-3', 'C', 'D',],
      ['A-4', 'B', 'C', 'D',],
      ['A-1', 'A-2', 'A-3',],
      ['A-1', 'A-2', 'A-4',],
      ['A-1', 'A-3', 'A-4',],
      ['A-2', 'A-3', 'A-4',],
      ['A-1', 'A-2', 'A-3', 'A-4',],
    ],

    # Made up recipe, just to reduce the timer
    [3, 2, 2] => [
      ['A-1', 'A-2', 'A-3',],
      ['A-1', 'B-1', 'C-1',],
      ['A-1', 'B-1', 'C-2',],
      ['A-1', 'B-2', 'C-1',],
      ['A-1', 'B-2', 'C-2',],

      ['A-2', 'B-1', 'C-1',],
      ['A-2', 'B-1', 'C-2',],
      ['A-2', 'B-2', 'C-1',],
      ['A-2', 'B-2', 'C-2',],
      
    ],
    [4, 2, 1] => [
      ['A-1', 'B-1', 'C',],
      ['A-1', 'B-2', 'C',],
      ['A-2', 'B-1', 'C',],
      ['A-2', 'B-2', 'C',],
      ['A-3', 'B-1', 'C',],
      ['A-3', 'B-2', 'C',],
      ['A-4', 'B-1', 'C',],
    ],
    [3, 3, 1] => [
      ['A-1', 'B-1', 'C',],
      ['A-1', 'B-2', 'C',],
      ['A-1', 'B-3', 'C',],
      ['A-2', 'B-1', 'C',],
      ['A-2', 'B-2', 'C',],
      ['A-2', 'B-3', 'C',],
      ['A-3', 'B-1', 'C',],
    ],
  }


  def recipe(recipe_key)
    RECIPES[recipe_key] || SmallGemMineRecipes.new.recipe(recipe_key)
  end
end

class SmallGemMineRecipes
  def recipe(key)
    states = states_from_counts(key)
    return make_small_recipe(states)
  end

  def make_small_recipe(states)
    return unless states.size == 7
    last_crumble = 0
    out = []
    7.times do |i|
      istate = states[i]
      (i + 1).upto(6) do |j|
	jstate = states[j]
	(j + 1).upto(6) do |k|
	  kstate = states[k]
	  if istate[:used] >= 7 || jstate[:used] >= 7 || kstate[:used] >= 7
	    next
	  end
	  r = make_one_workload(istate, jstate, kstate)
	  if r
	    out << r
	    if istate[:used] >= 7 || jstate[:used] >= 7 || kstate[:used] >= 7
	      last_crumble = out.size
	    end
	  end
	end
      end
    end
    if last_crumble == 0
      return out.slice(0, 3)
    else
      return out.slice(0, last_crumble)
    end
  end

  def make_one_workload(is, js, ks)
    good_wl = (is[:color] == js[:color] &&
	       js[:color] == ks[:color])
    good_wl ||= (is[:color] != js[:color] &&
		 js[:color] != ks[:color] &&
		 is[:color] != ks[:color] )
    if good_wl
      [is, js, ks].each {|s| s[:used] += 1}
      return [is[:name], js[:name], ks[:name], ]
    else
      return nil
    end
  end

  # Returns an array of state hashes, given the
  # count array.
  # State hash has keys :color, :used, :name
  def states_from_counts(counts)
    states = []
    letter = 'A'
    counts.each do |count|
      if count > 1
	count.times do |i|
	  states << make_state(letter, i)
	end
      else
	states << make_state(letter)
      end
      letter = letter.succ
    end
    return states
  end

  def make_state(letter, ind=nil)
    name = ''
    if ind.nil?
      name = letter
    else
      name = letter + '-' + (ind + 1).to_s
    end
    return {
      :name => name,
	:color => letter,
	:used => 0,
    }
  end
end




class OreStone
  attr_reader :color, :x, :y
  def initialize(x, y, color)
    @x, @y, @color = x, y, color
  end
end



class OreStoneScene < ARobot
  attr_reader :stones
  def initialize(bb_field, bb_mine, bb_avatar, delta, debug, base_denom)
    super()
    @base_denom = base_denom
    # The set of bounding boxes we've got.
    @boxes = []
    small_delta = [delta / 10, 4].max
    each_scanline(bb_field, bb_mine, bb_avatar) do |arr|
      if false
	arr.each do |p|
	  mm(p[0], p[1])
	end
      end
      process_scanline(arr, small_delta)
    end
    @boxes = merge_boxes(@boxes, small_delta)
    if  @boxes.size > 7
      del = small_delta
      4.times do
	del += small_delta
	@boxes = merge_boxes(@boxes, del)
	break if @boxes.size <= 7
      end
    end
    @stones = make_stones(@boxes)
  end

  def merge_boxes(boxes, del)
    out_list = []
    boxes = boxes.dup
    survivors = boxes.dup
    while (target = survivors.shift)
      survivors = merge_into(target, survivors, del)
      out_list << target
    end
    out_list
  end

  def merge_into(target, boxes, del)
    survivors = []
    loop do
      missed_all = true
      boxes.each do |box|
	if target.offset_for(box) <= del
	  missed_all = false
	  target.union!(box)
	else
	  survivors << box
	end
      end
      break if missed_all
      boxes = survivors
      survivors = []
    end
    survivors
  end

  # Build bounding boxes from the scanline, and add to the
  # @boxes list.  Start a new box, if the separation is larger than delta.
  def process_scanline(scanline, del)
    return if scanline.size == 0
    bb = nil
    xprev = -1000
    scanline.each do |xy|
      if bb.nil?
	bb = Bounds.new(xy)
      else
	if (xy[0] - xprev) <= del
	  bb.add(xy)
	else
	  @boxes << bb
	  bb = Bounds.new(xy)
	end
      end
      xprev = xy[0]
    end
    @boxes << bb
  end
  
  # Yields each scanline in the field of pixels.
  # The "scanline" is just an array of [x, y] entries that correspond
  # to a "orestone" color.
  # Coords that are inside "bb_mine" and "bb_avatar" will be excluded.
  def each_scanline(bb_field, bb_mine, bb_avatar)
    width = bb_field.xmax - bb_field.xmin + 1
    height = bb_field.ymax - bb_field.ymin + 1
    @pixel_block = screen_rectangle(bb_field.xmin, bb_field.ymin, width, height)
    height.times do |y|
      scanline = []
      width.times do |x|
	color = @pixel_block.color(x, y)
	r, g, b = color.red, color.green, color.blue
	if Clr.mine_color?(r, g, b)
	  screen_x, screen_y  = @pixel_block.to_screen(x, y)
	  screen_xy = [screen_x, screen_y]
	  unless bb_mine.contains?(screen_xy) || bb_avatar.contains?(screen_xy)
	    scanline << screen_xy
	  end
	end
      end
      yield(scanline)
    end
  end

  def smaller_boxes(boxes)
    out_boxes = []
    puts "Base denom is #{@base_denom}"
    boxes.each do |box|
      xod = ((box.xmax - box.xmin) / @base_denom).round
      yod = ((box.ymax - box.ymin) / @base_denom).round
      out_boxes << Bounds.new([box.xmin + xod, box.ymin + yod],
			      [box.xmax - xod, box.ymax - yod])
    end
    out_boxes
  end

  # Problems here: 
  # - The outer ledge of each stone is green (or perhaps
  #   some other color). We need to examine only the pixels
  #   near the centroid.
  # Returns an array of OreStones.
  def make_stones(boxes)
    boxes = smaller_boxes(boxes)
    ore_stones = []
    boxes.each do |box|
      color = first_color_found(box)
      ore_stones << OreStone.new(box.xcenter, box.ycenter, color)
    end
    return ore_stones
  end

  def first_color_found(box)
    box.ymin.upto(box.ymax) do |y|
      box.xmin.upto(box.xmax) do |x|
	color = Clr.color_symbol(@pixel_block.color_from_screen(x, y))
	return color if color
      end
    end
    return :black
  end

end

