require 'action'
require 'window'
require 'walker'

class PickStones < Action
  def initialize
    super("Pick Stones", "Misc")
  end

  def act
    loop do
      pt = find_point
      rclick_at pt unless pt.nil?
      AWindow.dismissAll if WindowGeom.isRightEdgeBorder(getColor(pt))
      puts "nothing" if pt.nil?
      sleep 3
    end
  end

  def stone_color?(color)
    r = color.red
    g = color.green
    b = color.blue

    return r > 190 && r < 210 && (r-g).abs < 2 && (r-b).abs < 2
  end

  def find_point
    pb = full_screen_capture
    center = Point.new(pb.width/2, pb.height/2)
    (pb.height/2).times do |r|
      pts = square_with_radius(center, r)
      # puts pts
      pts.each {|pt| return pt if stone_color?(pb.color(pt))}
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
