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
    field = Bounds.new(ul, lr)

    debug = @vals['debug'] == 'y'
    delay = @vals['delay'].to_f
    denom = @vals['base-denom'].to_f

    want_larges = @vals['large'] == 'y'

    w = PinnableWindow.from_point(point_from_hash(@vals, 'mine'))
    @debug = @vals['debug'] == 'y'
    rect = field.rect
    ControllableThread.check_for_pause
    w.click_on('Stop Working', 'tc')
    sleep_sec(5.0)
    before = PixelBlock.new(rect)
    w.click_on('Work this Mine', 'tc')
    sleep_sec(5.0)
    after = PixelBlock.new(rect)
    diff = ImageUtils.xor(before, after)
    brightness = ImageUtils.brightness(diff)
    globs = ImageUtils.globify(brightness, 1)
    p globs.size
    globs = globs.sort { |g1, g2| g2.size <=> g1.size }
    globs.each { |g| puts g.size }
    stones = []
    globs.each { |g| stones << points_to_stone(g) }
    stones.each {|s| p s}
    stones.each do |s|
      p = Point.new(s['x'], s['y'])

      mm(after.to_screen(p))
      sleep 2
    end
  end

  # Input here is a hash with Points as a key.
  # We look at the points, and return a hash with keys:
  # xmin, xmax, ymin, ymax, x, y.  x and y are for the centroid
  def points_to_stone(glob)
    xmin = ymin = 99999999
    xmax = ymax = 0
    xsum = ysum = 0
    glob.keys.each do |p|
      x, y = p.x, p.y
      xmin = x if x < xmin 
      ymin = y if y < ymin 

      xmax = x if x > xmax 
      ymax = y if y > ymax

      xsum += x
      ysum += y
    end

    {
      'xmin' => xmin,
      'ymin' => ymin,
      'xmax' => xmax,
      'ymax' => ymax,
      'x' => xsum / glob.keys.size, 
      'y' => ysum / glob.keys.size, 
    }
  end

  def old_act
    ul = [@vals['field.ul.x'].to_i, @vals['field.ul.y'].to_i]
    lr = [@vals['field.lr.x'].to_i, @vals['field.lr.y'].to_i]
    bb_field = Bounds.new(ul, lr)

    debug = @vals['debug'] == 'y'
    delay = @vals['delay'].to_f
    denom = @vals['base-denom'].to_f

    want_larges = @vals['large'] == 'y'

    w = PinnableWindow.from_point(point_from_hash(@vals, 'mine'))
    @debug = @vals['debug'] == 'y'
    ControllableThread.check_for_pause
    loop do
      begin
	ControllableThread.check_for_pause
        
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







