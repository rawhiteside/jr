class Bounds
  attr_reader :xmin, :xmax, :ymin, :ymax
  attr_reader :xradius, :yradius
  attr_reader :xcenter, :ycenter
  attr_reader :width, :height

  def initialize(xy, xy2=nil)
    @xmin = @xmax = @xcenter = xy[0]
    @ymin = @ymax = @ycenter = xy[1]
    @xradius = @yradius = 0
    @width = @height = 0
    add(xy2) if xy2
  end

  def self.rect_from_points(points)
    xmin = ymin = 99999999
    xmax = ymax = 0
    points.each do |p|
      x, y = p.x, p.y
      xmin = x if x < xmin 
      ymin = y if y < ymin 

      xmax = x if x > xmax 
      ymax = y if y > ymax

    end
    Rectangle.new(xmin, ymin, xmax - xmin, ymax - ymin)
  end

  def rect
    Rectangle.new(xmin, ymin, xmax - xmin, ymax - ymin)
  end

  def add(xy)
    @xmin = xy[0] if xy[0] < @xmin
    @ymin = xy[1] if xy[1] < @ymin

    @xmax = xy[0] if xy[0] > @xmax
    @ymax = xy[1] if xy[1] > @ymax

    @width = (@xmax - @xmin)
    @height = (@ymax - @ymin)
    @xradius = @width / 2.0
    @yradius = @height / 2.0
    @xcenter = @xmin + @xradius
    @ycenter = @ymin + @yradius
  end


  # Computes a separation between self and the other bounds.
  # If the bb's overlap, then zero.
  # If they don't overlap, then return x_separation + y_separation.
  def offset_for(other)
    return 0 if overlaps?(other)

    offx = 0
    offx = (other.xmin - @xmax) if other.xmin > @xmax
    offx = (@xmin - other.xmax) if other.xmax < @xmin

    offy = 0
    offy = (other.ymin - @ymax) if other.ymin > @ymax
    offy = (@ymin - other.ymax) if other.ymax < @ymin

    return offx + offy
  end

  # Do the boxes overlap?
  def overlaps?(other)
    # If the distance between the centers is less than or equal to
    # the sum of the two radii, then overlap.
    radiix = other.xradius + @xradius
    deltax = (other.xcenter - @xcenter).abs
    return false if deltax > radiix

    radiiy = other.yradius + @yradius
    deltay = (other.ycenter - @ycenter).abs
    return false if deltay > radiiy

    return true
  end

  def union!(other)
    add([other.xmin, other.ymin])
    add([other.xmax, other.ymax])
  end

  def contains?(xy)
    x = xy[0]
    y = xy[1]
    x >= @xmin && x <= @xmax && y >= @ymin && y <= @ymax
  end

  def spiral_for_radius(rad)
    pts = []
    xcenter = @xcenter.to_i
    ycenter = @ycenter.to_i
    len = rad * 2 + 1
    # Top strip
    pt = [xcenter - rad, ycenter - rad]
    pts += strip_for(pt, len, [1, 0])
    return pts if rad == 0

    # Bottom strip
    pt = [xcenter - rad, ycenter + rad]
    pts += strip_for(pt, len, [1, 0])
    
    len = len - 2

    # Left strip
    pt = [xcenter - rad, ycenter - rad + 1]
    pts += strip_for(pt, len, [0, 1])
    
    # Right strip
    pt = [xcenter + rad, ycenter - rad + 1]
    pts += strip_for(pt, len, [0, 1])

    return pts
  end

  def strip_for(pt, len, offset)
    strip = []
    pt = pt.dup
    len.times do
      if pt[0] >= @xmin && pt[0] < @xmax &&
	  pt[1] >= @ymin && pt[1] < @ymax
	strip << pt.dup
      end
      pt[0] += offset[0]
      pt[1] += offset[1]
    end
    return strip
  end

  def spiral
    pts = []
    rad = 0
    loop do
      chunk = spiral_for_radius(rad)
      break if chunk.size == 0
      pts += chunk
      rad += 1
    end
    return pts
  end
end
