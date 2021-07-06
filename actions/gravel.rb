require 'action'
require 'walker'
require 'pick_things'

class GravelAction < PickThings
  def initialize
    super('Gravel', 'Gather')
    @post_gather_wait = 2.5
  end

  def setup(parent)
    # Coords are relative to your head in cart view.
    gadgets = [
      {:type => :world_loc, :label => 'Smash location', :name => 'smash_loc'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)

  end

  def act
    inventory_window = InventoryWindow.find
    walker = Walker.new

    coords = grid_from_smash_loc

    loop do
      last_coord = nil
          coords.each do |coord|
            walker.walk_to(coord)
            sleep 2
            gather_until_none(walker, coord, inventory_window)
      end
    end
  end

  def gather_color?(pb, x, y)
    color = pb.get_color(x, y)
    r, g, b = color.red, color.green, color.blue
    return r > 150 && (r - g).abs < 15 && (r - b).abs < 15
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
    if (w = PinnableWindow.from_point(screen_x + 2, screen_y + 2))
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
