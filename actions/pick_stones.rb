require 'action'
require 'window'
require 'walker'
require 'pick_things'

class PickStones < PickThings
  def initialize
    super("Pick Stones", "Gather")

    @post_gather_wait = 2.5
  end

  def setup(parent)
    comps = [
      {:type => :world_loc, :name => 'start', :label => 'Starting coords.'},
      {:type => :point, :label => 'Drag to the Inventory window.', :name => 'inventory'},
      {:type => :combo, :label => 'Also watch for', :name => 'baux-gyp',
       :vals => ['Nothing', 'Bauxite', 'Gypsum'],},
      
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, comps)

    @vals
  end

  def act
    inventory_window = InventoryWindow.from_point(point_from_hash(@vals, 'inventory'))
    walker = Walker.new
    c  = WorldLocUtils.parse_world_location(@vals['start'])
    grid = [
      [c[0], c[1] - 1],
      [c[0], c[1] + 1],
      [c[0] - 1, c[1]],
      [c[0] + 1, c[1]],
    ]
    loop do
      grid.each do |coord|
        walker.walk_to(coord)
        sleep 1
        gather_until_none(walker, coord, inventory_window)
      end
    end
  end


  # This will cause the searcher to find a hit on a *mixture* of stone
  # and gypsum/bauxite colors.  I think that case rare, and an extra
  # click isn't a big deal, anyway.
  def gather_color?(pb, x, y)
    color = pb.color(x, y)
    r, g, b = color.red, color.green, color.blue
    # Stone.
    if r > 150 && (r - g).abs < 15 && (r - b).abs < 15
      return true
    end

    return false if @vals['baux-gyp'] == 'Nothing'
    hsb = Color.RGBtoHSB(r, g, b, nil)
    hsb[0] = (360 * hsb[0]).to_i
    hsb[1] = (256 * hsb[1]).to_i

    # Gypsum
    if @vals['baux-gyp'] == 'Gypsum'
      return (31..36).cover?(hsb[0]) && (85..100).cover?(hsb[1])
    end
    
    # Bauxite
    if @vals['baux-gyp'] == 'Bauxite'
      return (24..30).cover?(hsb[0]) && (100..140).cover?(hsb[1])
    end
    false
  end

end

Action.add_action(PickStones.new)
