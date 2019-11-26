require 'action'

class PickThings < Action
  def initialize(name, category)
    super(name, category)
  end

  def square_with_radius(center, r)
    pts = []
    # We start at not quite the upper left of the square.
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

  def hsb_for_point(pb, pt, cache)
    hsb = cache[pt]
    return hsb unless hsb.nil?
    color = pb.color(pt.x, pt.y)
    hsb = Color.RGBtoHSB(color.red, color.green, color.blue, nil)
    # NOTE:  Converting hue into degrees.
    hue = (hsb[0] * 360).to_i
    sat = (hsb[1] * 255).to_i
    val = (hsb[2] * 255).to_i
    cache[pt] = [hue, sat, val]
    return cache[pt]
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

  def stone?(pb, pt, cache)
    return pickable?(pb, pt, cache) do |hue, sat, val|
        # Near-perfectly grey things seem weird in HSB space. 
      (hue == 300 && sat < 9)||
        (hue == 120 && sat < 9) ||
        (hue == 0 && sat == 0 && val > 0)
    end
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


end
