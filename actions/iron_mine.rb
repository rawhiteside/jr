require 'action'
require 'convexhull'
require 'timer'
require 'set'
require 'm_choose_n'


import org.foa.ImageUtils

class IronMine < Action
  def initialize
    super('Mine iron', 'Misc')
  end
  def persistence_name
    'iron_mine'
  end
  def setup(parent)
    gadgets = [
      {:type => :frame, :label => 'Show me the stone area', :name => 'area',
       :gadgets => [
	 {:type => :point, :label => 'UL corner', :name => 'ul'},
	 {:type => :point, :label => 'LR corner', :name => 'lr'},
       ]
      },
      {:type => :point, :label => 'Pinned mine dialog', :name => 'mine'},
      {:type => :combo, :label => 'Debug level', :name => 'debug',
       :vals => ['0', '1', '2']},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end
  
  def act
    @debug_level = @vals['debug'].to_i
    mine_pt = point_from_hash(@vals, 'mine')
    field_rect = Rectangle.new(@vals['area.ul.x'].to_i, @vals['area.ul.y'].to_i,
			       @vals['area.lr.x'].to_i - @vals['area.ul.x'].to_i,
			       @vals['area.lr.y'].to_i - @vals['area.ul.y'].to_i)
    mine_window = PinnableWindow.from_point(mine_pt)
    loop do
      mine_once(mine_window, field_rect)
    end
  end

  def mine_once(win, rect)

    # returns the image of the ore field, and that image XOR-ed with
    # the empty field
    stones_image, xor_image = get_minefield_changes(win, rect)
    edges = ImageUtils.edges(stones_image)
    xor_edges = ImageUtils.edges(xor_image)
    
    stones = find_stones(stones_image, xor_image).select {|s| s.size > 100}
    if stones.nil?
      puts "Rejected. No stones found"
      UserIO.show_image(xor_image)
      return
    end
    stones = stones.sort { |a,b| b.size <=> a.size }[0,7]
    stones = stones[1,7] if stones.size < 7
    return unless stones

    stones = stones.sort{|a,b| a.max_point.y <=> b.max_point.y}
    stones.each {|s| s.set_properties}

    if @debug_level > 0
      mouse_over_stones(stones)
      stones.each {|s| puts s}
    end

    if @debug_level > 1
      show_crystal_points(stones, stones_image)
    end
    
    find_workloads_and_mine(stones)
  end

  def show_crystal_points(stones, image)
    points = []
    points = stones.inject([]) {|arr, stone| arr += stone.crystal_points}
    points_image = ImageUtils.image_from_points(image.buffered_image, points)
    UserIO.show_image(points_image)
  end

  def mouse_over_stones(stones)
    off = 15
    off_delay = 0.2
    stones.each do |s|

      mm(s.x, s.y)
      sleep_sec 1.0

      # Signal the crystal type.
      # horizontal wiggle:  wart
      # vertical wiggle: spike
      # diagonal wiggle: finger
      case s.crystal_type
      when :wart
        2.times {mm(s.x - off, s.y); sleep_sec(off_delay); mm(s.x + off, s.y); sleep_sec(off_delay); }
      when :finger
        2.times {mm(s.x - off, s.y - off); sleep_sec(off_delay); mm(s.x + off, s.y + off); sleep_sec(off_delay); }
      when :spike
        2.times {mm(s.x, s.y - off); sleep_sec(off_delay); mm(s.x, s.y + off); sleep_sec(off_delay); }
      end
    end
  end

  def mineable?(stones, arr)
    crystals  = stones.collect {|s| s.crystal_type}
    colors  = stones.collect {|s| s.color_symbol}

    (all_same(arr, crystals) || all_different(arr, crystals)) && 
      (all_same(arr, colors) || all_different(arr, colors))
  end

  def all_different(arr, attrs)
    0.upto(arr.size-1) do |i|
      (i+1).upto(arr.size-1) do |j|
	return false if attrs[arr[i]] == attrs[arr[j]]
      end
    end
    return true
  end

  def all_same(arr, attrs)
    val = attrs[arr[0]]
    arr.each{|i| return false if val != attrs[i]}
    return true
  end

  def actually_mine(stones, arr)
    delay = 0.2
    watcher = nil
    arr.each_index do |i|
      stone = stones[arr[i]]

      watcher = StoneHighlightWatcher.new(stone) if i == 0
      
      mm(stone.x, stone.y)
      sleep_sec(delay)
      str = (i == (arr.size - 1)) ? 's' : 'a'
      send_string(str)
      sleep_sec(delay)
      
      watcher.wait_highlight(true) if i == 0
    end
    watcher.wait_highlight(false)
  end

  # Provide a list of indices.  Mine it if it's mine-able.
  def maybe_mine(stones, arr)
    actually_mine(stones, arr) if mineable?(stones, arr)
    dismiss_popup_windows
  end

  def find_workloads_and_mine(stones)
    chooser = MChooseN.new
    chooser.each(stones.size, 6) {|arr| maybe_mine(stones, arr)} if stones.size >= 6
    chooser.each(stones.size, 5) {|arr| maybe_mine(stones, arr)} if stones.size >= 5
    chooser.each(stones.size, 3) {|arr| maybe_mine(stones, arr)} if stones.size >= 3
    chooser.each(stones.size, 4) {|arr| maybe_mine(stones, arr)} if stones.size >= 4
  end

  def dismiss_popup_windows
    while dismiss_one_popup_window
      sleep 0.1
    end
  end

  def dismiss_one_popup_window
    if win = PopupWindow.find
      win.dialog_click(Point.new(win.rect.width/2, win.rect.height - 20))
      sleep_sec 0.1
      return true
    end
    return false
  end

  # Returns two pixelblocks.  The first is the scene with the
  # orestones in it.  The second is the xor of this with the empty
  # field.
  def get_minefield_changes(win, rect)
    # First, clear the mine field and take a shot of the empty field
    win.refresh
    win.click_on('Stop')
    sleep_sec 3
    dismiss_popup_windows
    empty_img = PixelBlock.new(rect)

    # Now, mine, and get another shot with the ore stones.
    win.refresh
    while win.read_text =~ /can be worked/
      sleep_sec 3
      win.refresh
    end
    win.click_on('Work this Mine')
    sleep_sec 5
    stones_img = PixelBlock.new(rect)

    # Compute a new image that's the xor of the two images.
    return stones_img, ImageUtils.xor(stones_img, empty_img)
  end

  # Given the xor image of the field, figure out where the stones are.
  # a "glob" is just an array of Points corresponding to the orestone.
  # Return value is an array of these globs.
  def find_stones(stones_image, xor_image)
    brightness = ImageUtils.brightness(xor_image)
    globs = nil
    seconds = Timer.time_this do
      globs = get_globs(brightness, 10)
    end
    puts "Globify: #{seconds} seconds"

    stones = globs.collect {|points| IronOreStone.new(stones_image, brightness, points, @debug_level)}
  end

  # XXX DUP of method in sandmine. 
  def get_globs(brightness, threshold)

    # +got+ is an array of HashMaps (Java) in which keys are points.  values are just 1's.
    got = ImageUtils.globify(brightness, threshold)
    # Convert from java land to ruby land.
    globs = []
    got.each do |hash_map|
      points = []
      hash_map.key_set.each {|k| points << k}
      globs << points
    end

    # This is an array of arrays of points.
    globs

  end
end

# XXX Close DUP of class in sandmine.
class IronOreStone
  attr_accessor :points, :min_point, :max_point, :centroid, :rect
  attr_accessor :color_symbol, :crystal_type
  attr_reader :image
  attr_reader :crystal_points

  def initialize(image, brightness, points, debug_level)
    @image = image
    @debug_level = debug_level
    @brightness = brightness
    @points = points
    set_points
  end

  def set_properties
    set_color
    set_crystal
  end
  
  def color(p)
    @image.color(p)
  end

  # Just look at the stone points and pick the first color.
  MINE_COLORS = [:yellow, :cyan, :green]
  def set_color
    @points.each do |p|
      c = Clr.color_symbol(@image.color(p))
      if MINE_COLORS.include?(c)
        @color_symbol = c
        return
      end
    end
    @color_symbol = :black
  end
  
  def set_crystal
    cd = CrystalDetector.new(self, @debug_level)
    @crystal_type = cd.crystal_type
    @crystal_points = cd.crystal_points
  end


  def set_points
    xmin = ymin = 99999999
    xmax = ymax = 0
    xsum = ysum = 0
    @points.each do |p|
      x, y = p.x, p.y
      xmin = x if x < xmin 
      ymin = y if y < ymin 

      xmax = x if x > xmax 
      ymax = y if y > ymax

      xsum += x
      ysum += y
    end

    @min_point = Point.new(xmin, ymin)
    @max_point = Point.new(xmax, ymax)
    @centroid = Point.new(xsum / @points.size, ysum / @points.size)
    @rect = Rectangle.new(@min_point.x, @min_point.y,
                          @max_point.x - @min_point.x + 1,
                          @max_point.y - @min_point.y + 1)  
  end

  def to_screen(point)
    @image.to_screen(point)
  end

  # Is this really a good idea, Bob? 
  def x
    @image.to_screen(@centroid).x
  end

  def y
    @image.to_screen(@centroid).y
  end

  def size
    @points.size
  end

  def to_s
    "stone: size=#{@points.size}, color=#{@color_symbol}, crystal: #{@crystal_type} "
  end

  def rectangle
    Rectangle.new(@min_point.x, @min_point.y,
                  @max_point.x - @min_point.x, 
                  @max_point.y - @min_point.y)
  end
end

class CrystalDetector
  attr_reader :crystal_type
  attr_reader :crystal_points

  def initialize(stone, debug_level)
    @debug_level = debug_level
    
    iterations = 10
    @crystal_points = crystal_pixels(stone.image, stone.points)
    arr = iterate_neighbor_count(@crystal_points, iterations)
    
    if arr.size > 8
      # index of first element greater than 10 (arr is sorted.)
      if arr[8] > 66
        @crystal_type = :wart
      elsif arr[8] > 39
        @crystal_type = :finger
      else
        @crystal_type = :spike
      end
      if @debug_level > 0
        puts "Crystal type: #{@crystal_type}, probe val: #{arr[8]}"
      end
    else
      puts "arr bogus: #{arr}"
    end

  end


  def iterate_neighbor_count(points, iteration_count)
    # Put points into a hash as keys, with values being a count.
    return [] if points.nil? || points.size == 0
    hash = {}
    points.each {|p| hash[p] = 1.0}
    iteration_count.times do
      out_hash = {}
      points.each do |p|

        count = hash[p]
        [
          [-1, -1], [0, -1], [1, -1],
          [-1,  0],          [1,  0],
          [-1,  1], [0,  1], [1,  1],
        ].each do |off|
          target = Point.new(p.x + off[0], p.y + off[1])
          count += hash[target] if hash[target]
        end
        out_hash[p] = count
      end
      # Scale by max possible, so numbers don't get too big
      points.each { |p| out_hash[p] /= 9.0 }

      hash = out_hash
    end
    # return the max value
    sorted = hash.values.sort
    arr = []

    10.times do |i|
      index = sorted.size * i / 10
      arr << (sorted[index] * 100).to_i
    end
    File.open('mine-crystals.cvs', 'a') do |f|
      arr.each {|a| f.write(", #{a.to_s}")}
      f.puts ""
    end

    return arr
  end

  def crystal_color?(color)
    return true if color == Color::WHITE
    return true if color == Color::BLACK
    hsb = Color.RGBtoHSB(color.red, color.green, color.blue, nil)
    hue = hsb[0]
    if hue > 0.64 && hue < 0.76
      true
    else
      false
    end
  end

  def crystal_colorXXX?(color)
    r, g, b = color.red, color.green, color.blue
    return false unless (b >= g) && (b >= r)

    # Blue
    cut = b/5

    return true if (b - g) > cut && (b - r) > cut

    # Very bright, but not bright cyan
    sum = r + g + b
    return true if (sum > 550) && b >= g && b >= r && (g-r).abs < 50

    # Very dark
    return true if sum < 75
    
  end

  def crystal_pixels(img, points)
    points.select {|p| crystal_color?(img.color(p))}
  end

end

class StoneHighlightWatcher
  def initialize(stone)
    @stone = stone
    @rect = make_rect(stone, stone.image)
    @empty = PixelBlock.new(@rect)
  end

  def highlight?
    xor = ImageUtils.brightness(ImageUtils.xor(@empty, PixelBlock.new(@rect)))
    globs = ImageUtils.globify(xor, 10)

    return false if (globs.nil? || globs.size < 8)
    globs = globs.sort { |a,b| b.size <=> a.size }

    # Should be one large ring, and a bunch of little arrow things.
    globs[0].size > (globs[1].size * 10)
  end
  

  def wait_highlight(expect)
    start = Time.now
    loop do
      break if highlight? == expect
      break if (Time.now - start) > 4.0
      ARobot.shared_instance.sleep_sec(0.1)
    end
  end

  def make_rect(stone, image)
    srect = Rectangle.new(stone.rect)

    xy = image.to_screen(srect.x, srect.y)
    srect.x = xy[0]
    srect.y = xy[1]

    # A rectangle a little larger than the stone
    rect = Rectangle.new(srect.x - srect.width/4,
                         srect.y - srect.height/4,
                         (srect.width * 3) / 2,
                         (srect.height * 3) / 2)
    ss = ARobot.sharedInstance.screen_size
    rect.x = 0 if rect.x < 0
    rect.x = ss.width - 1 if rect.x >= ss.width

    rect.y = 0 if rect.y < 0
    rect.y = ss.height - 1 if rect.y >= ss.height

    return rect
  end

  
end

Action.add_action(IronMine.new)
