require 'action'
require 'walker'

class SiltAction < PickThings
  def initialize
    super('Silt', 'Gather')
  end

  def setup(parent)
    # Coords are relative to your head in cart view.
    gadgets = [
      {:type => :point, :label => 'Drag to the pinned WH menu.', :name => 'stash'},
      {:type => :point, :label => 'Drag to the Inventory window.', :name => 'inventory'},
      {:type => :world_path, :label => 'Path to walk', :name => 'path',
       :rows => 12, :custom_buttons => 2},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    @stash_window = PinnableWindow.from_point(point_from_hash(@vals, 'stash'))
    @inventory_window = InventoryWindow.from_point(point_from_hash(@vals, 'inventory'))

    walker = Walker.new
    # An array of boxes to search, in order spiraling out. 
    coords = WorldLocUtils.parse_world_path(@vals['path'])

    loop do
      last_coord = nil
      coords.each do |coord|
        # Its either coordinates [x, y], or the word "silt".
        if coord.kind_of?(Array)
	  walker.walk_to(coord)
          sleep 1
          last_coord = coord
        elsif coord == 'Stash'
          @stash_window.refresh
          HowMuch.max if @stash_window.click_on('Stash/Silt')
        elsif coord == 'Silt'
          sleep 0.2
          gather_at(walker, last_coord)
        end
      end
    end
  end

  def gather_at(walker, coords)
    loop do
      # Gather as many as we find, going from one silt pile to
      # another.
      got_some = gather_several
      return unless got_some
      # Go back to the starting point and check again for more.
      walker.walk_to(coords)
    end
  end

  def gather_several
    gathered_once = gather_once
    if gathered_once
      loop { break unless gather_once }
    end
    return gathered_once
  end
  
  def silt_color?(pixel_block, x, y)
    color = pixel_block.color(x, y)
    r, g, b = color.red, color.green, color.blue
    hsb = Color.RGBtoHSB(r, g, b, nil)
    hue = hsb[0]
    sat = hsb[1]
    return (hue > 0.08 && hue < 0.11 && sat < 0.18)
  end

  def gather_once
    pb = full_screen_capture
    center = Point.new(pb.width/2, pb.height/2)
    max_rad = pb.height/2 - 200
    max_rad.times do |r|
      pts = square_with_radius(center, r)
      pts.each  do |pt|
        state = try_gather(pb, pt)
        return true if state == :yes
        return false if state == :done_here
      end
    end
    
    return nil
  end

  # Returns:
  # :yes - gathered silt
  # :no - Nothing at this point
  # :done_here - Nothing in range.  Done at these world coordinates.
  
  def try_gather(pb, pt)

    all_silt = silt_color?(pb, pt.x, pt.y) &&
               silt_color?(pb, pt.x + 1, pt.y) &&
               silt_color?(pb, pt.x - 1, pt.y) &&
               silt_color?(pb, pt.x, pt.y + 1) &&
               silt_color?(pb, pt.x, pt.y - 1) 

    if all_silt
      @inventory_window.flush_text_reader
      inv_text_before = @inventory_window.read_text
      screen_x, screen_y  = pb.to_screen(pt.x, pt.y)
      point = Point.new(screen_x, screen_y)
      rclick_at(screen_x, screen_y, 0.2)
      sleep 0.3
      color = getColor(screen_x, screen_y)
      if WindowGeom.isRightEdgeBorder(color)
        AWindow.dismissAll
        return :done_here
      end
      # Wait for the inventory to change.  If not, then we clicked on
      # some ground that looked like silt.  Let's jus tmove along.
      5.times do
        sleep_sec 1
        @inventory_window.flush_text_reader
        inv_text = @inventory_window.read_text
        if inv_text != inv_text_before
          sleep 2.5
          return :yes
        end
      end
      return :done_here
    end

    return :no
  end

  def get_vals(parent)
  end
end

Action.add_action(SiltAction.new)

