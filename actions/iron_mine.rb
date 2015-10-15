require 'action'
require 'convexhull'
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

    @stones_pb, xor_pb = get_minefield_changes(win, rect)
    @stones = find_stones(xor_pb, @stones_pb)
    return unless @stones && @stones.size >= 7

    @stones = @stones.sort {|a,b| b.size <=> a.size}[0,7].sort{|a,b| a.ymax <=> b.ymax}
    return unless @stones && @stones.size == 7

    @colors = @stones.collect{|s| s.color(@stones_pb)}
    if @debug
      print "Colors are: " 
      p @colors
    end

    @gems = @stones.collect{|s| s.gem_shape(@stones_pb)}
    if @debug
      print "gems are: " 
      p @gems
    end

    if @debug
      @stones.each {|s| mm(@stones_pb.to_screen(s.center)); sleep_sec(1.0) }
    end
    
    find_recipes
  end

  def mineable?(arr)
    (all_same(arr, @gems) || all_different(arr, @gems)) && 
      (all_same(arr, @colors) || all_different(arr, @colors))
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

  def actually_mine(arr)
    delay = 0.2
    arr.each_index do |i|
      mm(@stones_pb.to_screen(@stones[arr[i]].center))
      sleep_sec(delay)
      str = (i == (arr.size - 1)) ? 's' : 'a'
      send_string(str)
      sleep_sec(delay)
    end
  end

  # Provide a list of indices.  Mine it if it's mine-able.
  def maybe_mine(arr)
    actually_mine(arr) if mineable?(arr)
    dismiss_popup_windows
  end

  def find_recipes
    chooser = MChooseN.new
    chooser.each(7, 6) {|arr| maybe_mine(arr)}
    chooser.each(7, 5) {|arr| maybe_mine(arr)}
    chooser.each(7, 4) {|arr| maybe_mine(arr)}
    chooser.each(7, 3) {|arr| maybe_mine(arr)}
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
    empty = PixelBlock.new(rect)

    # Now, mine, and get another shot with the ore stones.
    win.refresh
    while win.read_text =~ /can be worked/
      sleep_sec 3
      win.refresh
    end
    win.click_on('Work this Mine')
    sleep_sec 5
    stones = PixelBlock.new(rect)

    # Compute a new image that's the xor of the two images.
    return stones, ImageUtils.xor(stones, empty)
  end

  # This magic number obtained just by looking at stuff with color cop.
  BRIGHTNESS_CUTOFF = 10

  # Given the xor image of the field, figure out where the stones are.
  # This probably belongs in the fctory itself..
  def find_stones(pb_xor, pb_stones)
    # the factory consumes PxlRuns
    fac = IronOreStoneFactory.new(pb_stones)
    pb = ImageUtils.brightness(pb_xor)
    prun = nil
    pb.getHeight.times do |y|
      fac.next_row(y)
      prun = nil
      pb.getWidth.times do |x|
	pixel = pb.pixel(x, y)
	if pixel > BRIGHTNESS_CUTOFF
	  if prun
	    prun.last = x
	  else
	    prun = PxlRun.new(y, x, x)
	  end
	else
	  if prun
	    fac.add_pxl_run(prun)
	    prun = nil
	  end
	end
      end
      # Perhaps there was a dangling run constructed
      fac.add_pxl_run(prun) if prun
    end

    # Flush any trailing "stones" from the bottom of the bitmap.
    fac.next_row(pb.getHeight)
    fac.next_row(pb.getHeight + 1)

    return fac.stones
  end

  

end

# Holds groups of growing IronOreStones.  The add_pxl_run method
# accepts a PxlRun, and searches to find the IronOreStones that this
# fragment overlaps, and adds it.  This may result in stones being
# merged.
class IronOreStoneFactory
  def initialize(pb_stones)
    @pb_stones = pb_stones
    # Stones that may still grow with the addition of new runs.
    @live_list = []

    # Stones that can no longer grow, as they are too high in the
    # image for new runs to contribute.
    @dead_list = []
  end

  # Construct and return the list of 6 stones
  def stones
    @live_list + @dead_list
  end
  
  # Starting on row y.  Can move some stones from the live list onto the dead
  # list, perhaps.
  def next_row(y)
    live = []
    @live_list.each do |stone|
      if y > (stone.ymax + 1)
	@dead_list << stone if stone.size > 50
      else
	live << stone
      end
    end
    @live_list = live
  end

  def add_pxl_run(pr)
    first_found = nil
    merged = []
    @live_list.each do |stone|
      if stone.added?(pr)
	if first_found
	  first_found.merge(stone)
	  merged << stone
	else
	  first_found = stone
	end
      end
    end
    # If it didn't fit into any, then create a new stone.
    @live_list << IronOreStone.new(pr, @pb_stones) unless first_found

    # Now, remove all the stones that got merged away.
    merged.each {|stone| @live_list.delete(stone)}
  end
end

class IronOreStone
  attr_reader :pxl_run_hash, :ymax

  def initialize(pr, pb_stones)
    # This will hold y => [pr, pr, ...]
    # That is, for a given y value, the list of pxlruns
    @pxl_run_hash = {pr.y => [pr]}
    @ymax = pr.y
    @pb_stones = pb_stones
    @convex_hull = nil
    @center = nil
    @size = nil
  end

  # return a Point for the center of the stone.
  def center
    @center ||= compute_center
  end

  def compute_center
    # Find the central y value
    keys = @pxl_run_hash.keys
    ymin = keys.min
    ymax = keys.max
    ycenter = (ymin + ymax)/2
    # Now, find the center of the largest run
    row_runs = @pxl_run_hash[ycenter]
    xcenter = 0
    largest = 0
    row_runs.each do |pr|
      if (pr.last - pr.first) > largest
	largest = pr.last - pr.first
	xcenter = (pr.last + pr.first)/2
      end

      return Point.new(xcenter, ycenter)
    end
  end

  # Do the two provided pxlruns overlap?
  # We assume, without checking, that the two are in adjacent rows.
  def overlaps?(pr1, pr2)
    # x1 first is within the x2 range.
    return true if pr1.first >= pr2.first && pr1.first <= pr2.last

    # x1 last is within the x2 range.
    return true if  pr1.last >= pr2.first && pr1.last <= pr2.last

    # The final case is that pr2 is contained entirely within
    # pr2.  Here's the check for that case.
    return true if pr2.first >= pr1.first && pr2.first <= pr1.last

    return false
  end

  # Figure out the gem shape.
  # We do this by looking at the top of the stone.
  GEM_SIZE = 30
  def gem_shape(pb)
    robot = ARobot.sharedInstance
    return :wart if wart?
    return spike_or_finger
  end

  def spike_or_finger
    # Search below the highest point.
    ymin = @pxl_run_hash.keys.min
    # Just pick the first pr at the min y. There must be at least one.
    pr_ref = @pxl_run_hash[ymin][0]
    # find the center of this run.
    xcenter = (pr_ref.first + pr_ref.last) / 2

    # Count the dark pixels in a NxN surround of each point
    scansize = 3
    count = 0
    ymin.upto(ymin + scansize) do |y|
      (-scansize).upto(scansize) do |xoff|
	x = xcenter + xoff
	count+= 1 if contained?(x, y)
      end
    end
    # XXX puts "count = #{count}"
    # Another experimentally determined magic number.
    return count <= 12 ? :spike : :finger
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

  # We're going to look for dark pixels around the vertices of the
  # convex hull However, if they're too near to each other, we'll
  # double count.  So, build the list of points that's at least 7
  # pixels apart.
  def probe_points
    # Get the hull points. 
    # remove first and last points
    pts = convex_hull.dup
    pts.shift
    pts.pop

    probes = [pts[0]]
    1.upto(pts.size - 1) do |i|
      deltax = pts[i].x - pts[i-1].x
      deltay = pts[i].y - pts[i-1].y
      if (deltax * deltax + deltay * deltay) > 49
	probes << pts[i]
      end
    end
    
    probes
  end

  # Scheme 3 for wart detection.
  def wart?
    ymin = @pxl_run_hash.keys.min

    filled = 0
    # Count the number of mine pixels in the GEM_SIZE region.
    ymin.upto(ymin + GEM_SIZE) do |y|
      arr = @pxl_run_hash[y]
      if arr
	filled += arr.collect{|pr| pr.last - pr.first + 1}.inject{|sum, n| sum + n}
      end
    end
    # Now, compute the area of the convex hull, which also
    # uses GEM_SIZE rows.
    area = convex_hull_area
    ratio = filled.to_f/area.to_f
    # XXX puts "wart: #{area} / #{filled} ==> #{ratio}"
    # An experimental magic number
    return true if ratio > 0.9
    nil
  end

  def convex_hull_area
    @convex_hull_area ||= compute_convex_hull_area
  end

  def compute_convex_hull_area
    polygon_area(convex_hull)
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

  def convex_hull
    @convex_hull ||= compute_convex_hull
  end

  def compute_convex_hull
    # First, build the list of points holding the max and min x values
    # on each scanline.
    # Only the top GEM_SIZE scanlines
    ymin = @pxl_run_hash.keys.min
    pts = []
    ymin.upto(ymin + GEM_SIZE) do |y|
      arr = @pxl_run_hash[y]
      if arr
	minx = arr.collect{|pr| pr.first}.min
	maxx = arr.collect{|pr| pr.last}.max
	pts << Point.new(minx, y)
	pts << Point.new(maxx, y)
      end
    end

    # OK, now compute the convex hull of that set.
    ConvexHull.calculate(pts)
  end


  # Figure out the color.  This only really sorks for our specific mine.
  # The three colors in that mine are: red, black, and magenta.
  # The base is yellow, which we don't look for.
  # Give the original pixel block of the ore field, so we can look at its pixels.
  def color(pb)
    # Just iterate over al the pixels until we find a color.
    # If none found, then it's black
    @pxl_run_hash.each do |y, arr|
      arr.each do |pixel_run|
	pixel_run.first.upto(pixel_run.last) do |x|
	  c = color_symbol(pb.color(x, y))
	  return c if c
	end
      end
    end
    return :black
  end

  def color_symbol(color)
    Clr.color_symbol(color)
  end

  # Try to add the provided PxlRun to the stone.
  # See if it overlaps with anything in the previous row (pr.y - 1)
  def added?(pr)
    # We search the previous row (pr.y - 1)
    pxlruns = @pxl_run_hash[pr.y - 1]
    return false unless pxlruns && pxlruns.size > 0
    pxlruns.each do |pxlrun|
      if overlaps?(pr, pxlrun)
	current_y  = @pxl_run_hash[pr.y]
	if current_y
	  current_y << pr
	else
	  @pxl_run_hash[pr.y] = [pr]
	end
	@ymax = pr.y
	return true
      end
    end
    return false
  end

  # Need to cache/maintain this.
  # Pixel count
  def size
    @size ||= compute_size
  end

  def compute_size
    s = 0
    @pxl_run_hash.values.each do |prr|
      prr.each {|pr| s += pr.length}
    end
    return s
  end

  # Copy pxlruns from the other stone into us.
  def merge(other)
    other.pxl_run_hash.each do |y, row|
      my_row = @pxl_run_hash[y]
      if my_row
	merge_row(my_row, row)
      else
	@pxl_run_hash[y] = row
      end
    end
  end

  def merge_row(mine, his)
    his.each do |pr|
      mine << pr unless mine.include?(pr)
    end
  end

end

class PxlRun
  public
  attr_accessor :y, :first, :last
  def initialize(y, first, last)
    @y = y
    @first = first
    @last = last
  end

  # How many pixels in here?
  def length
    @last - @first + 1
  end

  # Is this equal to another one?
  def ==(other)
    @y == other.y && @first == other.first && @last == other.last
  end
end

Action.add_action(IronMine.new)
