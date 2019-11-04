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

  def stone_color?(pb, pt)

    [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]].each do |delta|
       color = pb.color(pt.x + delta[0], pt.y + delta[1])
       r, g, b = color.red, color.green, color.blue
       hsb = Color.RGBtoHSB(r, g, b, nil)

       # NOTE:  Converting hue into degrees.
       hue = (hsb[0] * 359).to_i

       return false unless hue == 300 || (hue == 0 && hsb[1] < 0.01)
     end

     return true
  end


end
