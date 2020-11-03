require 'java'
import java.awt.Point
import java.awt.Polygon

class ConvexHull < Polygon
  # Points for which the convex hull is to be computed. 
  def initialize(points)
    super()
    hull_points = calculate(points)
    # need x and y arrays.
    hull_points.each { |p| add_point(p.x, p.y) }
  end

  # Computing the area of a polygon looked complicated.  Just count
  # the pixels inside.
  def area
    rect = bounds
    count = 0
    rect.x.upto(rect.x + rect.width - 1) do |x|
      rect.y.upto(rect.y + rect.height - 1) do |y|
        count += 1 if contains(x, y)
      end
    end

    count
  end

  # after graham & andrew
  private
  def calculate(points)
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
  def determinant_function(p0, p1)
    proc { |p| ((p0.x-p1.x)*(p.y-p1.y))-((p.x-p1.x)*(p0.y-p1.y)) }
  end
  
  private
  def convex?(list_of_three, lower)
    p0, p1, p2 = list_of_three
    (determinant_function(p0, p2).call(p1) > 0) ^ lower
  end
  
end
