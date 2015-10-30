require 'action'
require 'convexhull'
require 'set'
require 'm_choose_n'

import org.foa.ImageUtils

class IronMine < Action
  def initialize
    super('Mine iron', 'Misc')
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
      {:type => :combo, :label => 'Debug mode?', :name => 'debug',
	:vals => ['y', 'n']},
    ]
    @vals = UserIO.prompt(parent, 'iron_mine', 'Mine Iron', gadgets)
  end
  
  def act
    @debug = @vals['debug'] == 'y'
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
    unless stones
      puts "Rejected. No stones found"
      return
    end
    stones = stones.sort { |a,b| b.size <=> a.size }[0,7]
    if stones.size < 7
      stones = stones[1,7]
    end
    stones = stones.sort{|a,b| a.max_point.y <=> b.max_point.y}
    stones.each {|s| s.set_properties}

    if @debug
      mouse_over_stones(stones)
      stones.each {|s| puts s}
    end
    
    find_recipes_and_mine(stones)
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
    highlight_blue_point = nil
    arr.each_index do |i|
      mm(stones[arr[i]].x, stones[arr[i]].y)
      sleep_sec(delay)
      str = (i == (arr.size - 1)) ? 's' : 'a'
      send_string(str)
      sleep_sec(delay)
      if i == 0
        sleep_sec(0.1)
        highlight_blue_point = find_highlight_point(stones[arr[i]])
      end
    end
    wait_for_highlight_gone(highlight_blue_point)
  end

  # Provide a list of indices.  Mine it if it's mine-able.
  def maybe_mine(stones, arr)
    actually_mine(stones, arr) if mineable?(stones, arr)
    dismiss_popup_windows
  end

  def find_recipes_and_mine(stones)
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
    globs = get_globs(brightness, 1)

    stones = globs.collect {|points| IronOreStone.new(stones_image, brightness, points, @debug)}
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

  end

  def highlight_blue?(color)
    r, g, b = color.red, color.green, color.blue
    
    return b > 100 && (b - g) < 20 && (b - r) > 30
  end

  def find_highlight_point(stone)
    y = stone.centroid.y
    x = stone.centroid.x
    stone.rectangle.width.times do |offset|
      # Examine only points NOT on the stone.
      y_offs = [0, -offset, -offset/2]
      y_offs.each do |y_off|
        local_point = Point.new(x + offset, y + y_off)
        if !stone.points.include?(local_point)
          point = stone.to_screen(local_point)
          return point if highlight_blue?(getColor(point))
        end
        local_point = Point.new(x + offset, y - y_off)
        if !stone.points.include?(local_point)
          point = stone.to_screen(local_point)
          return point if highlight_blue?(getColor(point))
        end
        local_point = Point.new(x - offset, y + y_off)
        if !stone.points.include?(local_point)
          point = stone.to_screen(local_point)
          return point if highlight_blue?(getColor(point))
        end
        local_point = Point.new(x - offset, y - y_off)
        if !stone.points.include?(local_point)
          point = stone.to_screen(local_point)
          return point if highlight_blue?(getColor(point))
        end
      end
    end

    puts "didn't find highlights "

    nil

  end
end

# XXX Close DUP of class in sandmine.
class IronOreStone
  attr_accessor :points, :min_point, :max_point, :centroid
  attr_accessor :color_symbol, :crystal_type
  attr_reader :image

  def initialize(image, brightness, points, debug)
    @image = image
    @debug = debug
    @brightness = brightness
    @points = points
    set_points
  end

  def set_properties
    puts "***********************************************************" if @debug
    set_color
    set_crystal
  end
  
  def color(p)
    @image.color(p)
  end

  # Just look at the stone points and pick the first color.
  MINE_COLORS = [:magenta, :cyan, :blue]
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
    @crystal_type = CrystalDetector.new(self, @debug).crystal_type
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


class CrystalDetector0
  attr_reader :crystal_type

  def initialize(stone)
    # Put the points in the top half of the stone (where the crystals are)
    # into a Set.  Set for fast query.
    cutoff = (stone.max_point.y - stone.min_point.y)/2 + stone.min_point.y
    set = Set.new(stone.points.select {|p| p.y < cutoff})

    dist = 3
    ratio = compute_ratio(set, 3)


    if ratio > 4.0
      @crystal_type = :wart
    elsif ratio > 2.7
      @crystal_type = :finger
    else
      @crystal_type = :spike
    end
    
  end

  def compute_ratio(set, dist)
    
    # Now, find the set of points without a right neighbor.
    right_holes = set.to_a.delete_if {|p| set.include?(Point.new(p.x + 1, p.y))}
    # Now.  The points in +right_holes+ have a hole to their right.
    # We want to know something about how far to the left the next
    # hole is.  Count the number of points in which the hole is within
    # the "magic number" +dist+
    right_count = count_points_with_nearby_hole(set, right_holes, [-1, 0], dist)

    # Now, do the same thing with up and down instead of right and left.
    up_holes = set.to_a.delete_if {|p| set.include?(Point.new(p.x, p.y - 1))}
    up_count = count_points_with_nearby_hole(set, right_holes, [0, 1], dist)

    # puts "right/left: #{right_holes.size}, #{right_count}"
    # puts "up/down: #{up_holes.size}, #{up_count}"
    # puts "total: #{right_holes.size + up_holes.size}, #{right_count + up_count}"
    # puts "Ratio: #{(right_holes.size + up_holes.size).to_f/(right_count + up_count).to_f}"
    if (right_count + up_count) == 0
      return 1000.0
    end
    (right_holes.size + up_holes.size).to_f/(right_count + up_count).to_f
  end


  def count_points_with_nearby_hole(set, edge_points, incr, dist)
    count = 0
    edge_points.each do |p|
      dist.times do |i|
        unless set.include?(Point.new(p.x + incr[0], p.y + incr[1]))
          count += 1
          next
        end
      end
    end

    count
    
  end
end


class CrystalDetector
  attr_reader :crystal_type

  def initialize(stone, debug)
    @debug = debug
    
    # Find the points in the top 1/4 of the stone.
    # cut = stone.min_point.y + (stone.max_point.y - stone.min_point.y)/2
    # top_points = stone.points.select {|p| p.y < cut}
    top_points = stone.points # XXX

    iterations = 10
    crystal_points = crystal_pixels(stone.image, top_points)
    fom = iterate_neighbor_count(crystal_points, iterations)

    puts "Iterations, value: #{iterations}, #{fom}"

    if spike?(top_points)
      @crystal_type = :spike
      return
    end
    if wart?(stone)
      @crystal_type = :wart
      return
    end
    @crystal_type = :finger
  end

  def spike?(top_points)
    # How many horizontal or vertical 1-pixel lines to we find?  These
    # will be point with either no neighbors left&right or no
    # neighbors up&down.
    set = Set.new(top_points)
    rl = top_points.count {|p| (!set.include?(Point.new(p.x - 1, p.y)) && (!set.include?(Point.new(p.x + 1, p.y))))}
    ud = top_points.count {|p| (!set.include?(Point.new(p.x, p.y - 1)) && (!set.include?(Point.new(p.x, p.y + 1))))}
    count = rl + ud
    return false if count == 0
    ratio = set.size / count.to_f

    puts "spike one-pixels: #{count}, ratio = #{ratio}" if @debug

    # Small values here are spikes.  Big numbers, fingers.
    ratio < 20.0
  end

  def iterate_neighbor_count(points, iteration_count)
    # Put points into a has as keys, ith values being a count.
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

    return hash.values.max
  end

  def crystal_pixel?(color)
    r, g, b = color.red, color.green, color.blue
    return false unless (r >= g) && (r >= b)

    # Red
    cut = r/5
    return true if (r - g) > cut && (r - b) > cut

    # Very bright, but not bright magenta
    sum = r + g + b
    return true if (sum > 550) && r >= g && r >= b && (g-b).abs < 50

    # Very dark
    return true if sum < 75
    
  end

  def crystal_pixels(img, points)
    points.select {|p| crystal_pixel?(img.color(p))}
  end

  def wart?(stone)
    cut = stone.min_point.y + (stone.max_point.y - stone.min_point.y)/3
    top_points = stone.points.select {|p| p.y < cut}
    glob = ImageUtils.globify_points(top_points).sort { |a,b| b.size <=> a.size }[0]
    # Compute the width of the bounding box.
    box1 = Bounds.rect_from_points(glob)

    # Now, remove the crystals and do it again.
    top_points.select! { |p| !(crystal_pixel?(stone.image.color(p))) }
#    bi = ImageUtils.image_from_points(stone.image.buffered_image, top_points)
#    UserIO.show_image(bi)
    glob = ImageUtils.globify_points(top_points).sort { |a,b| b.size <=> a.size }[0]
    box2 = Bounds.rect_from_points(glob)

    delta_w = box1.width - box2.width
    delta_h = box1.height - box2.height
    delta_area = delta_w * delta_h

    return false if delta_area <= 0

    ratio = (box1.width * box1.height).to_f / delta_area.to_f
    puts "wart? #{delta_w}, #{delta_h}, #{delta_area}, #{ratio} "
      
    # Small numbers are fingers (false).  Large ones warts (true).
    ratio > 8.0
  end

  def polygon_area(pts)
    # Duplicate the first pint at the end.
    pts = pts.dup
    pts << pts[0]
    # 
    area = 0.0
    0.upto(pts.size - 2) do |i|
      area += (pts[i].x*pts[i+1].y - pts[i+1].x*pts[i].y)
    end
    (area/2.0).abs
  end


  def convex_hull(points)
    # First, build the list of points holding the max and min x values
    # on each scanline.
    xmins = {}
    xmaxes = {}
    points.each do |p|
      if xmins[p.y].nil? || xmins[p.y].x > p.x
        xmins[p.y] = p
      end
      if xmaxes[p.y].nil? || xmaxes[p.y].x < p.x
        xmaxes[p.y] = p
      end
    end
    pts = xmins.values + xmaxes.values

    # OK, now compute the convex hull of that set.
    ConvexHull.calculate(points)
  end

end

Action.add_action(IronMine.new)
