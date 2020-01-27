require 'action'
require 'window'
require 'walker'
require 'pick_things'

class PickStones < PickThings
  def initialize
    super("Pick Stones", "Misc")
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
    start_coords = WorldLocUtils.parse_world_location(@vals['start'])
    inventory_win = InventoryWindow.from_point(point_from_hash(@vals, 'inventory'))

    walker = Walker.new
    walker.walk_to(start_coords)
    sleep 1
    prev_text = nil
    loop do

      # Get rid of a popup message if it's there. Like, from digging
      # or a Tower Hour.
      PopupWindow.dismiss

      pt = find_pickable
      if pt.nil?
        walker.walk_to(start_coords)
        sleep 0.5
      else
        prev_text = inventory_win.read_text
        rclick_at(pt, 0.1)
        sleep 0.1
        color = getColor(pt)
        AWindow.dismissAll if WindowGeom.isOuterBorder(color)
      end        
      sleep 4
      curr_text = inventory_win.read_text

      if prev_text == curr_text
        walker.walk_to(start_coords)
        sleep 0.5
      else
        prev_text = curr_text
      end
    end
  end


  def find_pickable
    pb = full_screen_capture
    cache = {}
    center = Point.new(pb.width/2, pb.height/2)
    off = 40
    off = 0 if @vals['baux-gyp'] == 'Nothing'
    (-(150 + off) + pb.height/2).times do |r|
      pts = square_with_radius(center, r + off)
      pts.each  do |pt|
        return pt if stone?(pb, pt, cache)
        return pt if @vals['baux-gyp'] == 'Bauxite' && bauxite?(pb, pt, cache)
        return pt if @vals['baux-gyp'] == 'Gypsum' && gypsum?(pb, pt, cache)
      end
    end
    
    return nil
  end

end

Action.add_action(PickStones.new)
