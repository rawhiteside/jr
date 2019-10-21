require 'action'
require 'window'
require 'walker'

class PickStones < Action
  def initialize
    super("Pick Stones", "Misc")
  end

  def setup(parent)
    comps = [
      {:type => :world_loc, :name => 'start', :label => 'Starting coords.'},
      {:type => :number, :name => 'count', :label => 'Stone coubt before return to start. '},
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

      pt = find_point
      if pt.nil?
        puts "Nothing to pick"
      else
        rclick_at(pt, 0.1)
        sleep 0.1
        color = getColor(pt)
        AWindow.dismissAll if WindowGeom.isRightEdgeBorder(color)
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

  def stone_color?(pb, pt)

    [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]].each do |delta|
       color = pb.color(pt.x + delta[0], pt.y + delta[1])
       r = color.red
       g = color.green
       b = color.blue

       return false unless r > 170 && r < 210 && (r-g).abs < 3 && (r-b).abs < 3
     end

     return true
  end

  def find_point
    pb = full_screen_capture
    center = Point.new(pb.width/2, pb.height/2)
    (pb.height/2).times do |r|
      pts = square_with_radius(center, r)
      pts.each {|pt| return pt if stone_color?(pb, pt)}
    end
    
    return nil
  end

  def square_with_radius(center, r)
    pts = []
    # We start at not quite the upper left.  
    pt_curr = Point.new(center.x - r, center.y - r)
    incrs = [Point.new(1, 0), Point.new(0, 1), Point.new(-1, 0), Point.new(0, -1)]
    incrs.each do |incr|
      (2 * r).times do
        # Increment the point.
        pt_curr.translate(incr.x, incr.y)
        pts << Point.new(pt_curr)
      end
    end

    return pts
  end
end

Action.add_action(PickStones.new)