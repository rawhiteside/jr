require 'action'
require 'bounds'
require 'walker'

class SiltAction < Action
  def initialize
    super('Silt', 'Gather')
  end

  def path_coords
    xvals = []
    yvals = []
    x = -929.0
    while x > -958
      xvals << x.to_i
      x -= 3.5
    end
    y = 5345.0
    while y > 5317
      yvals << y.to_i
      y -= 3.5
    end
    coords = []
    yvals.each do |y|
      xvals.each do |x|
	coords << [x, y]
      end
      xvals = xvals.reverse
    end
    return coords
  end

  def stash(walker)
    
    stash_path = [[-925, 5340], [-932, 5355]]
    walker.walk_path(stash_path)
    if @stash_window.click_on('Stash/Silt')
      HowMuch.new(:max)
    end
    walker.walk_path(stash_path.reverse)
    @carry_current = 0
  end

  def setup(parent)
    # Coords are relative to your head in cart view.
    gadgets = [
      {:type => :point, :label => 'UL Corner of gather region', :name => 'ul'},
      {:type => :point, :label => 'LR Corner of gather region', :name => 'lr'},
      {:type => :point, :label => 'Drag to the pinned WH menu.', :name => 'stash'},
      {:type => :number, :label => 'Remaining carry.', :name => 'carry'},
      {:type => :workd_path, :label => 'Path to walk', :name => 'path'},
    ]
    @vals = UserIO.prompt(parent, 'silt', 'Silt', gadgets)
  end

  def act
    @stash_window = PinnableWindow.from_point(point_from_hash(@vals, 'stash'))

    @carry_max = @vals['carry'].to_i
    @carry_current = 0

    box = Bounds.new([@vals['ul.x'].to_i, @vals['ul.y'].to_i],
		     [@vals['lr.x'].to_i, @vals['lr.y'].to_i])

    walker = Walker.new
    # An array of boxes to search, in order spiraling out. 
    sub_boxes = make_regions(box)
    # coords = path_coords
    coords = WorldLocUtils.parse_world_path(@vals['path'])

    loop do
      coords.each do |coord|
	walker.walk_to(coord)
	loop do
	  break unless gather_once(sub_boxes)
	  @carry_current += 10
	  if @carry_current >= @carry_max
	    stash(walker)
	  end
	end
      end
    end
  end

  
  
  def silt_color?(pixel_block, x, y)
    color = pixel_block.color(x, y)
    r, g, b = color.red, color.green, color.blue
    return false unless r > 110 && r < 175
    delrg = r - g
    return false unless delrg >= 6 && delrg < 15
    delgb = g - b
    return delgb >= 6 && delgb < 15
  end

  def gather_once(boxes)
    boxes.each do |box|
      pixel_block = screen_rectangle(box.xmin, box.ymin, box.width, box.height)
      2.upto(box.height - 3) do |y|
	2.upto(box.width - 3) do |x|
	  if silt_color?(pixel_block, x, y) &&
	      silt_color?(pixel_block, x-1, y) &&

	      silt_color?(pixel_block, x-1, y-1) &&
	      silt_color?(pixel_block, x, y-1) &&
	      silt_color?(pixel_block, x-2, y) &&
	      silt_color?(pixel_block, x-2, y-2) &&
	      silt_color?(pixel_block, x, y-2)

	      silt_color?(pixel_block, x+1, y) &&
	      silt_color?(pixel_block, x+1, y+1) &&
	      silt_color?(pixel_block, x, y+1) &&
	      silt_color?(pixel_block, x+2, y) &&
	      silt_color?(pixel_block, x+2, y+2) &&
	      silt_color?(pixel_block, x, y+2)
	    screen_x, screen_y  = pixel_block.to_screen(x, y)
	    rclick_at(screen_x, screen_y)
	    sleep_sec 5
	    return true
	  end
	end
      end
    end
    return false
  end

  # Splits the bounding box into a 5x5 array of sub-boxes.
  def make_regions(bbox)
    spiral = Bounds.new([0,0], [5,5]).spiral
    xvals = []
    yvals = []
    5.times do |i|
      xvals << (bbox.xmin + bbox.width * i * 0.2).to_i
      yvals << (bbox.ymin + bbox.height * i * 0.2).to_i
    end
    xvals << bbox.xmax
    yvals << bbox.ymax

    boxes = []
    spiral.each do |ij|
      i = ij[0]
      j = ij[1]
      boxes << Bounds.new([xvals[i], yvals[j]], [xvals[i+1], yvals[j+1]])
    end
    
    return boxes
  end

  def get_vals(parent)
  end
end

Action.add_action(SiltAction.new)

