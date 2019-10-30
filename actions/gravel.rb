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
      {:type => :world_loc, :label => 'Smash location', :name => 'location'},
      {:type => :number, :label => 'Count until stash', :name => 'pick_count'}
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    @stash_window = PinnableWindow.from_point(point_from_hash(@vals, 'stash'))
    @inventory_window = InventoryWindow.from_point(point_from_hash(@vals, 'inventory'))

    @walker = Walker.new
    coords = WorldLocUtils.parse_world_location(@vals['location'])
    radius = 2

    (-radius).upto(radius) do |xoff|
      (-radius).upto(radius) do |yoff|
        gather_here([coords[0] + xoff, coords[1] + yoff])
      end
    end
  end

  def gather_here(w_coords)
    @walker.walk_to(w_coords)
    
  end
                     
end
