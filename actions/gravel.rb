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
      {:type => :point, :label => 'Drag to the Inventory window.', :name => 'inventory'},
      {:type => :world_loc, :label => 'Smash location', :name => 'smash_loc'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    @inventory_window = InventoryWindow.from_point(point_from_hash(@vals, 'inventory'))

    walker = Walker.new

    coords = grid_from_smash_loc

    loop do
      last_coord = nil
      coords.each do |coord|
	walker.walk_to(coord)
        sleep 2
        gather_until_none(walker, coord)
      end
    end
  end

  def click_on_this?(pb, pt)
    color = pb.color(pt.x, pt.y)
    r, g, b = color.red, color.green, color.blue
    hsb = Color.RGBtoHSB(r, g, b, nil)
    hue = hsb[0]
    sat = hsb[1]
    val = hsb[2]
    # Near-perfectly grey things seem weird in HSB space. 
    return (hue == 300 && sat < 9)||
           (hue == 120 && sat < 9) ||
           (hue == 0 && sat == 0 && val > 0)
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

  def check_for_post_click_window(screen_x, screen_y)
    if (w = PinnableWindow.from_point(screen_x + 4, screen_y))
      if w.read_text.include?('too far')
        AWindow.dismiss_all
        return :true
      end
      if w.click_on('Pick')
        return false
      else
        AWindow.dismiss_all
        return :true
      end
    end
  end
end

Action.add_action(GravelAction.new)
