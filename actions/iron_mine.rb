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
      sleep_sec 1.5

      # Signal the gem type.
      # horizontal wiggle:  wart
      # vertical wiggle: spike
      # diagonal wiggle: finger
      case s.gem_type
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
    gems  = stones.collect {|s| s.gem_type}
    colors  = stones.collect {|s| s.color_symbol}

    (all_same(arr, gems) || all_different(arr, gems)) && 
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
    colors = []
    stone.rectangle.width.times do |offset|
      # Examine only points NOT on the stone.
      local_point = Point.new(x + offset, y - offset)
      if !stone.points.include?(local_point)
        point = stone.to_screen(local_point)
        color = getColor(point)
        colors << color
        return point if highlight_blue?(color)
      end
    end

    puts "didn't find highlights "

    nil

  end
end

# XXX Close DUP of class in sandmine.
class IronOreStone
  attr_accessor :points, :min_point, :max_point, :centroid
  attr_accessor :color_symbol, :gem_type
  attr_reader :image

  def initialize(image, brightness, points, debug)
    @image = image
    @debug = debug
    @brightness = brightness
    @points = points
    set_points
  end

  def set_properties
    set_color
    set_gem
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
    
  def set_gem
    @gem_type = GemDetector.new(self, @debug).gem_type
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
    "stone: size=#{@points.size}, color=#{@color_symbol}, gem: #{@gem_type} "
  end

  def rectangle
    Rectangle.new(@min_point.x, @min_point.y,
                  @max_point.x - @min_point.x, 
                  @max_point.y - @min_point.y)
  end
end


class GemDetector0
  attr_reader :gem_type

  def initialize(stone)
    # Put the points in the top half of the stone (where the gems are)
    # into a Set.  Set for fast query.
    cutoff = (stone.max_point.y - stone.min_point.y)/2 + stone.min_point.y
    set = Set.new(stone.points.select {|p| p.y < cutoff})

    dist = 3
    ratio = compute_ratio(set, 3)


    if ratio > 4.0
      @gem_type = :wart
    elsif ratio > 2.7
      @gem_type = :finger
    else
      @gem_type = :spike
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

class GemDetector1
  attr_reader :gem_type

  def initialize(stone)
    @gem_type = find_gem_shape(stone)
  end

  # Figure out the gem shape.
  # We do this by looking at the top of the stone.
  GEM_SIZE = 30
  def find_gem_shape(stone)

    cutoff = stone.min_point.y + GEM_SIZE
    # Count the number of mine pixels in the GEM_SIZE region.
    top_points =  stone.points.select {|p| p.y <= cutoff}

    return :wart if wart?(top_points)

    return spike_or_finger(stone, top)
  end

  def spike_or_finger(stone, top_points)
    # Search below the highest point.
    ymin = stone.min_point.y

    # Find the points at the top.  There must be at least one.
    top_row = top_points.select {|p| p.y == ymin}
    # Now, pick the middle one.
    ref_point = top_row[top_row.size/2]

    # Count the mine pixels in a rectangular region around that point.
    count = 0
    region_size = 4
    region_size.times do |yoff|
      (-region_size).upto(region_size) do |xoff|
        if top_points.include?(Point.new(ref_point.x + xoff, ref_point.y + yoff))
          count += 1
        end
      end
    end
     puts "count = #{count}"
    # Another experimentally determined magic number.
    return count <= 11 ? :spike : :finger
  end

  # Is the provided pixel contained in the run lists?
  def contained?(x, y)
    arr = @pxl_run_hash[y]
    return false unless arr
    arr.each do |pr|
      return true if x >= pr.first && x <= pr.last
    end
    return false
  end

  # Scheme 3 for wart detection.
  def wart?(top_points)
    filled = top_points.size
    # Now, compute the area of the convex hull, which also
    # uses GEM_SIZE rows.
    area = convex_hull_area(top_points)
    ratio = filled.to_f/area.to_f
    # XXX puts "wart: #{area} / #{filled} ==> #{ratio}"
    # An experimental magic number
    return true if ratio > 0.9
    nil
  end

  def convex_hull_area(points)
    compute_convex_hull_area(points)
  end

  def compute_convex_hull_area(points)
    polygon_area(convex_hull(points))
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
    compute_convex_hull(points)
  end

  def compute_convex_hull(points)
    # First, build the list of points holding the max and min x values
    # on each scanline.
    # Only the top GEM_SIZE scanlines
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
    ConvexHull.calculate(pts)
  end

end

class GemDetector
  attr_reader :gem_type

  def initialize(stone, debug)
    @debug = debug
    
    # Find the points in the top 1/4 of the stone.
    cut = stone.min_point.y + (stone.max_point.y - stone.min_point.y)/4
    top_points = stone.points.select {|p| p.y < cut}

    if wart?(stone)
      @gem_type = :wart
      return
    end
    @gem_type = finger_or_spike(top_points)

  end

  def finger_or_spike(top_points)
    # How many horizontal or vertical 1-pixel lines to we find?  These
    # will be point with either no neighbors left&right or no
    # neighbors up&down.
    set = Set.new(top_points)
    rl = top_points.count {|p| (!set.include?(Point.new(p.x - 1, p.y)) && (!set.include?(Point.new(p.x + 1, p.y))))}
    ud = top_points.count {|p| (!set.include?(Point.new(p.x, p.y - 1)) && (!set.include?(Point.new(p.x, p.y + 1))))}
    count = rl + ud
    ratio = set.size / count.to_f

    puts "one-pixels: #{count}, ratio = #{ratio}" if @debug

    (ratio < 30.0) ? :spike : :finger

  end

  def wart?(stone)
    cut = stone.min_point.y + (stone.max_point.y - stone.min_point.y)/3
    top_points = stone.points.select {|p| p.y < cut}
    set_points = Set.new(top_points)
    if top_points.size != set_points.size
      puts "*************Top points, set_points: #{top_points.size}, #(set_points.size)"
    end

    # Compute the area of the convex hull.
    hull = convex_hull(top_points)
    area = polygon_area(hull)

    filled = top_points.size
    ratio = filled.to_f/area.to_f
    puts "wart: #{area} / #{filled} ==> #{ratio}" if @debug
    # An experimental magic number
    return true if ratio > 0.88
    nil
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
