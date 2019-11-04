require 'action'
require 'walker'
require 'pick_things'

class GravelAction < PickThings
  def initialize
    super('Gravel', 'Gather')
  end

  def setup(parent)
    # Coords are relative to your head in cart view.
    gadgets = [
      {:type => :point, :label => 'Drag to the pinned WH menu.', :name => 'stash'},
      {:type => :point, :label => 'Drag to the Inventory window.', :name => 'inventory'},
      {:type => :world_loc, :label => 'Smash location', :name => 'smash_loc'},
      {:type => :world_loc, :label => 'Location near WH', :name => 'stash_loc'},
      {:type => :number, :label => 'Count until stash', :name => 'pick_count'}
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    @stash_window = PinnableWindow.from_point(point_from_hash(@vals, 'stash'))
    @inventory_window = InventoryWindow.from_point(point_from_hash(@vals, 'inventory'))
    @stash_count = @vals['pick_count'].to_i
    @picked_count = 0

    walker = Walker.new

    coords = grid_from_smash_loc

    loop do
      last_coord = nil
      coords.each do |coord|
	walker.walk_to(coord)
        sleep 2
        gather_at(walker, coord)
        go_and_stash if @picked_count >= @stash_count
      end
    end
  end


  def grid_from_smash_loc
    coords = []
    smash = WorldLocUtils.parse_world_location(@vals['smash_loc'])
    -3.upto(3) do |yoff|
      -3.upto(3) do |xoff|
        coords << [smash[0] + xoff, smash[1] + yoff]
      end
    end
    return coords
  end

  # Gather nearby things repeatedly, just wandering wherever it takes
  # you. When you run out of things, return to these coords and do it
  # again.  Repeat *that* until there's nothing at the coords.
  def gather_at(walker, coords)
    loop do
      # Gather as many as we find, going from one silt pile to
      # another.
      got_some = gather_several
      return unless got_some
      # Go back to the starting point and check again for more.
      walker.walk_to(coords)
      sleep 2
    end
  end

  # Just gather the nearest thing until there's nothing to gather.
  # You may wander off following the things to gather.
  def gather_several
    gathered_once = gather_once
    if gathered_once
      loop { break unless gather_once }
    end
    return gathered_once
  end

  # Gather the nearest thing. Return whether there was anything to
  # gather.
  def gather_once
    pb = full_screen_capture
    center = Point.new(pb.width/2, pb.height/2)
    max_rad = pb.height/2 - 150
    max_rad.times do |r|
      pts = square_with_radius(center, r)
      pts.each  do |pt|
        if stone_color?(pb, pt)
          state = gather_at_pixel(pb, pt)
          return true if state == :yes
          return false if state == :done_here
        end
      end
    end
    
    return nil
  end

  # Returns:
  # :yes - gathered silt
  # :no - Nothing at this screen point
  # :done_here - Nothing in range.  Done at these world coordinates.

  def gather_at_pixel(pb, pt)

    @inventory_window.flush_text_reader
    inv_text_before = @inventory_window.read_text
    screen_x, screen_y  = pb.to_screen(pt.x, pt.y)
    point = Point.new(screen_x, screen_y)
    rclick_at(screen_x, screen_y, 0.2)
    sleep 0.3
    color = getColor(screen_x, screen_y)
    if (w = PinnableWindow.from_point(screen_x + 4, screen_y))
      if w.read_text.include?('too far')
        AWindow.dismiss_all
        return :done_here
      end
      AWindow.dismiss_all unless w.click_on('Pick')
    end

    # Wait for the inventory to change.  If not, then we clicked on
    # some ground that looked like something to gather.  Let's just
    # move along.
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
end

Action.add_action(GravelAction.new)
