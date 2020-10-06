require 'action'
require 'walker'

class SiltAction < PickThings
  def initialize
    super('Silt', 'Gather')
    @post_gather_wait = 3
  end

  def setup(parent)
    # Coords are relative to your head in cart view.
    gadgets = [
      {:type => :point, :label => 'Drag to the pinned WH menu.', :name => 'stash'},
      {:type => :world_path, :label => 'Path to walk', :name => 'path',
       :rows => 12, :custom_buttons => 2},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    @stash_window = PinnableWindow.from_point(point_from_hash(@vals, 'stash'))

    inventory_window = InventoryWindow.find
    walker = Walker.new
    coords = WorldLocUtils.parse_world_path(@vals['path'])

    loop do
      last_coord = nil
      coords.each do |coord|
        # Its either coordinates [x, y], or one of the words "Silt", "Stash".
        if coord.kind_of?(Array)
	  walker.walk_to(coord)
          sleep 2
          last_coord = coord
        elsif coord == 'Stash'
          @stash_window.refresh
          HowMuch.max if @stash_window.click_on('Stash/Silt')
        elsif coord == 'Silt'
          sleep 0.2
          count = gather_until_none(walker, last_coord, inventory_window)
        end
      end
    end
  end
  
  def gather_color?(pixel_block, x, y)
    color = pixel_block.color(x, y)
    r, g, b = color.red, color.green, color.blue
    return r > g && g > b && r > 200 && (r-b) < 25
  end

end

Action.add_action(SiltAction.new)

