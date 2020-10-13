require 'action'
require 'actions/abstract_mine'

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
      
      {:type => :combo, :label => 'Gem color', :name => 'gem_color',
       :vals => ['red', 'green', 'blue', 'cyan', 'magenta', 'yellow', 'black'],},
      
      {:type => :combo, :label => 'Debug mode?', :name => 'debug',
       :vals => ['y', 'n']},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end
  
  def act
    origin = point_from_hash(@vals, 'field.ul')
    width = @vals['field.lr.x'].to_i - origin.x
    height = @vals['field.lr.y'].to_i - origin.y
    @field_rect = Rectangle.new(origin.x, origin.y, width, height)
    @debug = @vals['debug'] == 'y'
    log_result "Debug = #{@debug}"
    @stone_count = @vals['stone-count'].to_i
    @delay = @vals['delay'].to_f
    @gem_color = @vals['gem_color']
    
    w = PinnableWindow.from_point(point_from_hash(@vals, 'mine'))
    
    loop do
      begin
        check_for_pause
        stones = mine_get_stones(w)
        assign_colors_to_stones(stones)
        mine_stones(stones, true, @delay)
      rescue BadWorkloadException => e
  	log_result 'Bad workload exception.'
  	# No need for anything.  Just mine again.
      end
      sleep 1 while dismiss_strange_windows
    end
  end
  
  def assign_colors_to_stones(stones)
    stones.each do |ore_stone|
      
      
      rect = ore_stone.rectangle
      sums = Hash.new(0)
      sums[:red] = 0  # put at least one element in there. 
      rect.x.upto(rect.x + rect.width) do |x|
        rect.y.upto(rect.y + rect.height) do |y|
          
          color = @stones_image.color_from_screen(x, y)
          sym = Clr.color_symbol(color, @gem_color, @debug)
          sums[sym] = sums[sym] + 1 if (sym)
        end
      end
      log_result sums.to_s
      if @debug
        sums.each_key do |k|
          log_result "Color: #{k}, count #{sums[k]}, area: #{rect.width * rect.height}, ratio: #{sums[k].to_f/(rect.width * rect.height)}"
        end
      end
      max_count = sums.values.max
      ratio = max_count.to_f / (rect.width * rect.height)
      if ratio > 0.002     # Magic number!!
        sums.each_key do |k|
          if sums[k] == max_count
            ore_stone.color_symbol = k
            break
          end
        end
      else
        ore_stone.color_symbol = @gem_color.to_sym
      end
      log_result "Picked: #{ore_stone.color_symbol}" if @debug
      log_result "--" if @debug
      unless ore_stone.color_symbol
        log_result "this should not happen"
        puts "this should not happen"
      end
      
    end
    picked = stones.collect {|s| s.color_symbol}
    log_result picked.to_s
    if @debug
      p picked
    end
    
  end
  
  
  def wait_for_mine(w)
    loop do
      w.refresh
      break unless w.read_text =~ /This mine can be/
      sleep(1)
    end
  end
  
  def field_shot
    PixelBlock.new(@field_rect)
  end

  def mine_get_stones(w)
    wait_for_mine(w)
    w.click_on('Stop Working', 'tc')
    sleep(5.0)
    
    @empty_image = field_shot
    w.click_on('Work this Mine', 'tc')
    sleep(10.0)
    @stones_image = field_shot
    
    @diff_image = ImageUtils.xor(@empty_image, @stones_image)
    # brightness = ImageUtils.shrink(ImageUtils.brightness(@diff_image), 0)
    brightness = ImageUtils.brightness(@diff_image)
    globs = get_globs(brightness)
    puts globs.size
    globs = globs.sort { |g1, g2| g2.size <=> g1.size }
    globs = globs.slice(0, @stone_count)
    puts globs.size
    stones = []

    globs.each { |g| 
      # Stones will hold the sets of points.  These points will be in
      # screen coordinates.
      stones << points_to_stone(@stones_image, g) 
    }
    
    stones.sort! {|a, b| a.min_point.y  <=> b.min_point.y}
    
    if (@debug)
      mouse_over_stones(stones)
    end
    
    stones
    
  end

  def get_globs(brightness)
    # A +glob+ is just a hash with points as keys.  Points are in the
    # coord system of the +brightness+ image.
    got = Globifier.globify(brightness)
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
  # Input points are in the coordinate system of +pb+.
  # Points stored into the stone will be screen coordinates.
  # Returns an OreStone, which just has a bunch of attrs.
  def points_to_stone(pb, points)
    points.collect!{|p| pb.to_screen(p)}
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

    stone = OreStone.new
    stone.points = points
    stone.point_set = Set.new(points)
    stone.min_point = Point.new(xmin, ymin)
    stone.max_point = Point.new(xmax, ymax)
    stone.centroid = Point.new(xsum / points.size, ysum / points.size)

    stone

  end


  def mouse_over_stones(stones)
    stones.each do |s|
      mm(s.x, s.y)
      sleep 1.0
    end
  end

  def dismiss_strange_windows
    if win = PopupWindow.find
      log_result 'Dismissed a window'
      win.dialog_click(Point.new(win.rect.width/2, win.rect.height - 20))
      sleep 0.01
      return true
    end
    return false
  end


  def mine_stones(stones, want_larges, delay)

    check_for_pause

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
    # Sometimes the gem seem slow to arrive.  Don't "Stop working" 
    # too quickly.
    sleep 2
  end

  def log_result(msg)
    tsmsg = "#{Time.now.to_s} : #{msg}"
    File.open('mine.log', 'a') {|f| f.puts(tsmsg)}
  end

  def run_recipe(recipes, stones_by_name, delay)
    recipes.each do |recipe|
      run_one_workload(recipe, stones_by_name, delay)
    end
  end

  def run_one_workload(recipe, stones_by_name, delay)
    first_stone = nil
    recipe.each_index do |i|
      
      name = recipe[i]
      stone = stones_by_name[name]
      first_stone = stone if i == 0

      is_last_stone = (i == ((recipe.size - 1))) 
      key = 'A'
      key = 'S' if is_last_stone

      send_string_at(stone.x, stone.y, key, delay)
    end

    wait_for_highlight_gone(first_stone)
    dismiss_strange_windows    
  end

  def wait_for_highlight_gone(stone, timeout_secs = 6)
    start = Time.new
    
    sleep 0.2
    return if dismiss_strange_windows    
    
    loop do
      sleep 0.1
      return if dismiss_strange_windows
      highlight_count = count_highlight_pixels(stone)
      if highlight_count < 20  # Magic number
        return
      end
      if (Time.new - start) > timeout_secs
        log_result "highlight wait time-out (6 seconds)"
        return nil
      end
    end

  end
  
  def highight_color?(pb, x, y)
    color = pb.color(x, y)
    hsb = Color.RGBtoHSB(color.red, color.green, color.blue, nil)
    hue = hsb[0] * 360  # Angle
    sat = hsb[1] * 255
    return (186..196).cover?(hue) && (80..97).cover?(sat)
  end

  def count_highlight_pixels(stone)
    count = 0
    pb = big_stone_pic(stone)
    pb.height.times do |y|
      pb.width.times do |x|
        count += 1 if highight_color?(pb, x, y)
      end
    end
    return count
  end
  
  
  # A pb larger than the stone, which will include the highlight rung. 
  def big_stone_pic(stone)
    rect = stone.rectangle
    r = Rectangle.new(rect.x - 100, rect.y - 100, rect.width + 200, rect.height + 200)
    pb = PixelBlock.new(r)
    return pb
  end
  
  def send_string_at(x, y, str, delay)
    mm(x, y)
    sleep delay
    send_string(str)
    sleep delay
    if win = PopupWindow.find
      raise BadWorkloadException.new(win)
    end
  end

end

Action.add_action(SandMine.new)

class OreStone
  attr_accessor :points, :min_point, :max_point, :centroid
  attr_accessor :color_symbol, :gem_type, :point_set

  def initialize

  end

  def x
    @centroid.x
  end
  def y
    @centroid.y
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
