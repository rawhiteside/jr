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

  def pickable?(pb, pt, cache)
    size = 1
    (-size).upto(size) do |off|
      pt_tmp = Point.new(pt.x + off, pt.y)
      hsb = hsb_for_point(pb, pt_tmp, cache)
      hue, sat, val = hsb[0], hsb[1], hsb[2]
      return false unless yield(hue, sat, val)

      pt_tmp = Point.new(pt.x, pt.y + off)
      hsb = hsb_for_point(pb, pt_tmp, cache)
      hue, sat, val = hsb[0], hsb[1], hsb[2]
      return false unless yield(hue, sat, val)
    end

    return true
  end


  def stone?(pb, pt, cache)
    return pickable?(pb, pt, cache) do |hue, sat, val|
      # Near-perfectly grey things seem weird in HSB space. 
      (hue == 300 && sat < 9)||
        (hue == 120 && sat < 9) ||
        (hue == 0 && sat == 0 && val > 0)
    end
  end


  def bauxite?(pb, pt, cache)

    return pickable?(pb, pt, cache) do |hue, sat, val|
      (24..30).cover?(hue) && (100..140).cover?(sat)
    end
  end

  def gypsum?(pb, pt, cache)
    return pickable?(pb, pt, cache) do |hue, sat, val|
      (31..36).cover?(hue) && (85..100).cover?(sat)
    end

  end

end

Action.add_action(PickStones.new)
