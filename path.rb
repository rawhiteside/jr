require 'java'
import java.awt.Point
import java.awt.Rectangle

class PathSegment
  attr_reader :rectangle, :pt1, :pt2
  def initialize(pt1, pt2)
    @pt1 = Point.new(pt1)
    @pt2 = Point.new(pt2)

    xmin = [@pt1.x, @pt2.x].min
    ymin = [@pt1.y, @pt2.y].min

    xmax = [@pt1.x, @pt2.x].max
    ymax = [@pt1.y, @pt2.y].max

    @rectangle = Rectangle.new(xmin, ymin, xmax - xmin, ymax - ymin)
  end

  def self.from_xy(xy1, xy2)
    PathSegment.new(Point.new(xy1[0],xy1[1]), Point.new(xy2[0], xy2[1]))
  end

  def ==(other)
    self.pt1 == other.pt1 && self.pt2 == other.pt2
  end

  def overlap?(other)
    @rectangle.intersects(other.rectangle)
  end

  

end
