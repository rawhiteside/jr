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
      {:type => :number, :name => 'count', :label => 'Stone coubt before return to start. '},
      {:type => :combo, :label => 'Also watch for', :name => 'baux-gyp',
       :vals => ['Nothing', 'Bauxite', 'Gypsum'],},
      
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, comps)

    @vals
  end

  def act
    count_max = @vals['count'].to_i
    start_coords = WorldLocUtils.parse_world_location(@vals['start'])
    walker = Walker.new
    walker.walk_to(start_coords)
    sleep 1
    count = 0

    loop do

      # Get rid of a popup message if it's there. Like, from digging
      # or a Tower Hour.
      PopupWindow.dismiss

      pt = find_pickable
      if pt.nil?
        puts "Nothing to pick"
      else
        rclick_at(pt, 0.1)
        sleep 0.1
        color = getColor(pt)
        AWindow.dismissAll if WindowGeom.isOuterBorder(color)
      end        
      sleep 4
      if count >= count_max
        walker.walk_to(start_coords)
        sleep 0.5
        count = 0
      else
        count += 1
      end
    end
  end


  def find_pickable
    pb = full_screen_capture
    cache = {}
    center = Point.new(pb.width/2, pb.height/2)
    (-190 + pb.height/2).times do |r|
      pts = square_with_radius(center, r + 40)
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
