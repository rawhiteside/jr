require 'java'
import java.awt.Point

module ConvexHull
  # after graham & andrew
  def self.calculate(points)
    lop = points.sort_by { |p| p.x }
    left = lop.shift
    right = lop.pop
    lower, upper = [left], [left]
    lower_hull, upper_hull = [], []
    det_func = determinant_function(left, right)
    until lop.empty?
      p = lop.shift
      ( det_func.call(p) < 0 ? lower : upper ) << p
    end
    lower << right
    until lower.empty?
      lower_hull << lower.shift
      while (lower_hull.size >= 3) &&
	  !convex?(lower_hull.last(3), true)
	last = lower_hull.pop
	lower_hull.pop
	lower_hull << last
      end
    end
    upper << right
    until upper.empty?
      upper_hull << upper.shift
      while (upper_hull.size >= 3) &&
	  !convex?(upper_hull.last(3), false)
	last = upper_hull.pop
	upper_hull.pop
	upper_hull << last
      end
    end
    upper_hull.shift
    upper_hull.pop
    lower_hull + upper_hull.reverse
  end
  
  private
  
  def self.determinant_function(p0, p1)
    proc { |p| ((p0.x-p1.x)*(p.y-p1.y))-((p.x-p1.x)*(p0.y-p1.y)) }
  end
  
  def self.convex?(list_of_three, lower)
    p0, p1, p2 = list_of_three
    (determinant_function(p0, p2).call(p1) > 0) ^ lower
  end
  
end
