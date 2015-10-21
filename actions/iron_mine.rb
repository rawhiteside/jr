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
    UserIO.show_image(xor_image)
    UserIO.show_image(edges)
    UserIO.show_image(xor_edges)
    return
    
    stones = find_stones(stones_image, xor_image).select {|s| s.size > 100}
    return unless stones && stones.size >= 7

    stones = stones.sort {|a,b| b.size <=> a.size}[0,7].sort{|a,b| a.max_point.y <=> b.max_point.y}

    if @debug
      mouse_over_stones(stones)
    end

    stones.each {|s| s.set_properties}

    if @debug
      stones.each {|s| puts s}
    end
    
    find_recipes_and_mine(stones)
  end

  def mouse_over_stones(stones)
    stones.each do |s|
      mm(s.x, s.y)
      sleep_sec 1.5
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
    chooser.each(7, 6) {|arr| maybe_mine(stones, arr)}
    chooser.each(7, 5) {|arr| maybe_mine(stones, arr)}
    chooser.each(7, 4) {|arr| maybe_mine(stones, arr)}
    chooser.each(7, 3) {|arr| maybe_mine(stones, arr)}
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

    stones = globs.collect {|points| IronOreStone.new(stones_image, brightness, points)}
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
      local_point = Point.new(x + offset, y)
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

# XXX DUP of class in sandmine.
class IronOreStone
  attr_accessor :points, :min_point, :max_point, :centroid
  attr_accessor :color_symbol, :gem_type

  def initialize(image, brightness, points)
    @image = image
    @brightness = brightness
    @points = points
    set_points
  end

  def set_properties
    set_color
    set_gem
  end
  
  # Just look at the stone points and pick the first color.
  MINE_COLORS = [:red, :magenta]
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
    # Put the points in the top half of the stone (where the gems are)
    # into a Set.  Set for fast query.
    cutoff = (@max_point.y - @min_point.y)/2 + @min_point.y
    set = Set.new(@points.select {|p| p.y < cutoff})

    dist = 3
    ratio = compute_ratio(set, 3)
    @ratio2 = compute_ratio(set, 2)
    @ratio4 = compute_ratio(set, 4)


    if ratio > 4.0
      @gem_type = :wart
    elsif ratio > 2.7
      @gem_type = :finger
    else
      @gem_type = :spike
    end
    @ratio3 = ratio
    
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
    "stone: size=#{@points.size}, color=#{@color_symbol}, gem: #{@gem_type}, ratio2: #{@ratio2}, ratio3: #{@ratio3}, ratio4: #{@ratio4}"
  end

  def rectangle
    Rectangle.new(@min_point.x, @min_point.y,
                  @max_point.x - @min_point.x, 
                  @max_point.y - @min_point.y)
  end
end

Action.add_action(IronMine.new)
