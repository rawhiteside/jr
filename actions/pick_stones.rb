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
      {:type => :combo, :label => 'Also watch for', :name => 'baux-gyp',
       :vals => ['Nothing', 'Bauxite', 'Gypsum'],},
      
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, comps)

    @vals
  end

  def act
    inventory_window = InventoryWindow.find
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

  def check_for_post_click_window(x, y)
    w = PinnableWindow.from_point(x+2, y+2)
    return unless w
    if w.click_on("Pick")
      return false
    else
      AWindow.dismissAll 
      return true
    end
  end


  # This will cause the searcher to find a hit on a *mixture* of stone
  # and gypsum/bauxite colors.  I think that case rare, and an extra
  # click isn't a big deal, anyway.
  def gather_color?(pb, x, y)
    color = pb.getColor(x, y)
    r, g, b = color.red, color.green, color.blue
    # Stone.
    if r > 125 && (r - g).abs < 15 && (r - b).abs < 15 && r < 200
      return true
    end

    return false if @vals['baux-gyp'] == 'Nothing'
    hsb = Color.RGBtoHSB(r, g, b, nil)
    hsb[0] = (360 * hsb[0]).to_i
    hsb[1] = (256 * hsb[1]).to_i
    hsb[2] = (256 * hsb[2]).to_i

    # Gypsum
    if @vals['baux-gyp'] == 'Gypsum'
      g_hue = 36
      g_sat = 73
      g_val = 219
      return (hsb[0] - g_hue).abs < 6 && (hsb[1] - g_sat).abs < 6 && (hsb[2] - g_val).abs < 10
      # return (31..36).cover?(hsb[0]) && (85..100).cover?(hsb[1])
    end
    
    # Bauxite
    if @vals['baux-gyp'] == 'Bauxite'
      return (24..30).cover?(hsb[0]) && (100..140).cover?(hsb[1])
    end
    false
  end

end

Action.add_action(PickStones.new)
