require 'action'
require 'bounds'
require 'walker'

class SiltAction < Action
  def initialize
    super('Silt', 'Gather')
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
      {:type => :world_path, :label => 'Path to walk', :name => 'path', :aux => "Silt"},
    ]
    @vals = UserIO.prompt(parent, 'silt', 'Silt', gadgets)
  end

  def act
    @stash_window = PinnableWindow.from_point(point_from_hash(@vals, 'stash'))


    box = Bounds.new([@vals['ul.x'].to_i, @vals['ul.y'].to_i],
		     [@vals['lr.x'].to_i, @vals['lr.y'].to_i])

    walker = Walker.new
    # An array of boxes to search, in order spiraling out. 
    sub_boxes = make_regions(box)
    coords = WorldLocUtils.parse_world_path(@vals['path'])

    loop do
      last_coord = nil
      coords.each do |coord|
        # Its either coordinates [x, y], or the word "silt".
        if coord.kind_of?(Array)
	  walker.walk_to(coord)
          last_coord = coord
        else
          gather_at(walker, last_coord, sub_boxes)
        end
      end
    end
  end

  def gather_at(walker, coords, sub_boxes)
    loop do
      # Gather as many as we find, going from one silt pile to
      # another.
      got_some = gather_several(sub_boxes)
      return unless got_some
      # Go back to the starting point and check again for more.
      walker.walk_to(coords)
    end
  end

  def gather_several(sub_boxes)
    gathered_once = gather_once(sub_boxes)
    if gathered_once
      loop { gather_once(sub_boxes) }
    end
    return gathered_once
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

          # Search around [x, y]
          all_silt = true
          -2.upto(2) do |xoff|
            -2.upto(2) do |yoff|
              unless silt_color?(pixel_block, x + xoff, y + yoff)
	        all_silt = false 
                break
              end
            end
            break unless all_silt
          end
          if all_silt
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

