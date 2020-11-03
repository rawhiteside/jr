class SquareWithRadius
  def self.square_with_radius(center, r)
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
end
