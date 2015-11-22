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
      {:type => :point, :label => 'Drag to pinned mine menu', :name => 'mine'},

      {:type => :text, :label => 'How many stones?', :name => 'stone-count',},

      {:type => :text, :label => 'Key delay?', :name => 'delay',},

      {:type => :combo, :label => 'Debug mode?', :name => 'debug',
       :vals => ['y', 'n']},
    ]
    @vals = UserIO.prompt(parent, 'sand_mine', 'Mine sand', gadgets)
  end

  def act
    origin = point_from_hash(@vals, 'field.ul')
    width = @vals['field.lr.x'].to_i - origin.x
    height = @vals['field.lr.y'].to_i - origin.y
    @field_rect = Rectangle.new(origin.x, origin.y, width, height)
    @debug = @vals['debug'] == 'y'
    @stone_count = @vals['stone-count'].to_i
    @delay = @vals['delay'].to_f
    
    w = PinnableWindow.from_point(point_from_hash(@vals, 'mine'))

    loop do
      begin
        ControllableThread.check_for_pause
        stones = mine_get_stones(w)
        assign_colors_to_stones(stones)
        mine_stones(stones, true, @delay)
      rescue BadWorkloadException => e
	puts 'Bad workload exception.'
	# No need for anything.  Just mine again.
      end
      sleep_sec 1 while dismiss_strange_windows
    end
  end

  SEARCH_FRACTION = 0.4
  def assign_colors_to_stones(stones)
    stones.each do |ore_stone|
      # Bounds is a weird, old, class, but has that "spiral" method.
      # We'll search in the central portion of the stone.
      # Compute the central search Bounds from the two ul/lr points
      stone_rect = ore_stone.rectangle
      fract = (1.0 - SEARCH_FRACTION) / 2.0
      xoff = (stone_rect.width * fract).to_i
      yoff = (stone_rect.height * fract).to_i
      x1 = stone_rect.x + xoff
      y1 = stone_rect.y + yoff
      x2 = stone_rect.x + stone_rect.width - xoff
      y2 = stone_rect.y + stone_rect.height - xoff
      bounds = Bounds.new([x1, y1], [x2, y2])
      bounds.spiral.each do |xy|
        color = @stones_image.color(xy[0], xy[1])
        sym = Clr.color_symbol(color)
        if (sym)
          ore_stone.color_symbol = sym
          break
        end
      end
      ore_stone.color_symbol ||= :black
    end
  end

  
  def wait_for_mine(w)
    loop do
      w.refresh
      break unless w.read_text =~ /This mine can be/
      sleep_sec(1)
    end
  end
  
  def mine_get_stones(w)
    wait_for_mine(w)
    w.click_on('Stop Working', 'tc')
    sleep_sec(5.0)

    @empty_image = PixelBlock.new(@field_rect)
    w.click_on('Work this Mine', 'tc')
    sleep_sec(5.0)
    @stones_image = PixelBlock.new(@field_rect)

    @diff_image = ImageUtils.xor(@empty_image, @stones_image)
    brightness = ImageUtils.shrink(ImageUtils.brightness(@diff_image), 40)
    globs = get_globs(brightness, 1)
    globs = globs.sort { |g1, g2| g2.size <=> g1.size }
    globs = globs.slice(0, @stone_count)
    stones = []
    if @debug
      if globs.size == @stone_count && globs[0].size > 2 * globs[@stone_count-1].size
        UserIO.show_image(@empty_image)
        UserIO.show_image(@stones_image)
        UserIO.show_image(@diff_image)
      end
    end
    globs.each { |g| stones << points_to_stone(g) }

    if (@debug)
      mouse_over_stones(stones)
    end

    stones
    
  end

  def get_globs(brightness, threshold)
    got = ImageUtils.globify(brightness, threshold)
    # Convert from java land to ruby land.
    globs = []
    got.each do |hash_map|
      points = []
      hash_map.key_set.each {|k| points << k}
      globs << points
    end

    globs

  end


  # Input here is a hash with Points as a key.
  # Returns an OreStone, which just has a bunch of attrs.
  def points_to_stone(points)
    xmin = ymin = 99999999
    xmax = ymax = 0
    xsum = ysum = 0
    points.each do |p|
      x, y = p.x, p.y
      xmin = x if x < xmin 
      ymin = y if y < ymin 

      xmax = x if x > xmax 
      ymax = y if y > ymax

      xsum += x
      ysum += y
    end

    stone = OreStone.new(@stones_image)
    stone.points = points
    stone.min_point = Point.new(xmin, ymin)
    stone.max_point = Point.new(xmax, ymax)
    stone.centroid = Point.new(xsum / points.size, ysum / points.size)

    stone

  end


  def mouse_over_stones(stones)
    stones.each do |s|
      mm(s.x, s.y)
      sleep_sec @delay
    end
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
      color = stone.color_symbol
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
      run_one_workload(recipe, stones_by_name, delay)
      # Fixes issue with the very first orestone in a workload?
      sleep_sec(0.5) 
    end
  end

  def run_one_workload(recipe, stones_by_name, delay)
    blue_point = nil
    recipe.each_index do |i|
      name = recipe[i]
      stone = stones_by_name[name]
      
      key = 'A'
      key = 'S' if i == (recipe.size - 1)

      send_string_at(stone.x, stone.y, key, delay)

      # If this was the first stone, find a resulting blue pixel
      # from the highlight circle.
      if i == 0
        blue_point = find_highlight_point(stone)
        # First stone funny? Visually, it looks like this somethines
        # doesn't work.
        if blue_point.nil?
          puts "No highlight.  Waiting..."
          sleep_sec 0.5
          blue_point = find_highlight_point(stone)
          if blue_point
            puts "It's there now!"
          else
            puts "waiting didn't help.  Sending again."
            send_string_at(stone.x, stone.y, key, delay)
            blue_point = find_highlight_point(stone)
            if blue_point.nil?
              puts "STILL No highlight.  Sending again!" 
              send_string_at(stone.x, stone.y, key, delay)
              blue_point = find_highlight_point(stone)
              if blue_point
                puts "Yay!  Got it that time."
              else
                puts "Never found it.  Going with nil"
              end
            else
              puts "Found it."
            end
          end
        end
      end
    end

    wait_for_highlight_gone(blue_point)
  end


  def wait_for_highlight_gone(p)
    if p.nil?
      sleep 3
      return
    end
    start = Time.new
    until !highlight_blue?(getColor(p))
      sleep_sec 0.5
      break if (Time.new - start) > 6
    end
    sleep_sec @delay
  end

  def highlight_blue?(color)
    r, g, b = color.red, color.green, color.blue
    return b > 100 && (b - r) > 40 && (g - r) > 30
  end

  def find_highlight_point(stone)
    y = stone.centroid.y
    x = stone.centroid.x
    colors = []
    stone.rectangle.width.times do |offset|
      # Examine only points NOT on the stone.
      local_point = Point.new(x + offset, y)
      if !stone.points.include?(local_point)
        point = @stones_image.to_screen(local_point)
        color = getColor(point)
        colors << color
        return point if highlight_blue?(color)
      end
    end

    puts "didn't find highlights "

    nil

  end

  def send_string_at(x, y, str, delay)
    mm(x, y)
    sleep_sec delay
    send_string(str)
    sleep_sec delay
    if win = PopupWindow.find
      raise BadWorkloadException.new(win)
    end
  end

  def log_strange_window(w)
    log_result(w.read_text)
  end
end

Action.add_action(SandMine.new)

class OreStone
  attr_accessor :points, :min_point, :max_point, :centroid
  attr_accessor :color_symbol, :gem_type

  def initialize(pb)
    @pb = pb
  end

  def x
    @pb.to_screen(@centroid).x
  end
  def y
    @pb.to_screen(@centroid).y
  end

  def to_s
    "stone: size=#{@points.size}, centroid=[#{@centroid.x}, #{@centroid.y}], color=#{@color_symbol}, rectangle: #{rectangle.toString()}"
  end

  def rectangle
    Rectangle.new(@min_point.x, @min_point.y,
                  @max_point.x - @min_point.x, 
                  @max_point.y - @min_point.y)
  end
end


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
