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
    hue = (hsb[0] * 359).to_i
    sat = (hsb[1] * 255).to_i
    val = (hsb[2] * 255).to_i
    cache[pt] = [hue, sat, val]
    return cache[pt]
  end

  def stone_color?(pb, pt, cache)
    size = 2
    -size.upto(size) do |xoff|
      -size.upto(size) do |yoff|
        hsb = hsb_for_point(pb, pt, cache)
        hue, sat, val = hsb[0], hsb[1], hsb[2]

        # Near-perfectly grey things seem weird in HSB space. 
        return false unless (hue == 300 && sat < 6)||
                            (hue == 120 && sat < 6) ||
                            (hue == 0 && sat == 0 && val > 0)
      end
     end

     return true
  end


end
