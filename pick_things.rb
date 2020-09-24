require 'action'

# A super class for gathering stuff:  silt, gravel, dig stones...
# Main entry is "gather_until_done".
# 
# You must implement click_on_this?(pb, pt), which tells whether you
# might gather by clicking on the provided point.
#
# You might also need to override check_for_post_click_window
class PickThings < Action
  def initialize(name, category)
    super(name, category)
  end


  # Gather nearby things repeatedly, just wandering wherever it takes
  # you. When you run out of things, return to these coords and do it
  # again.  Repeat *that* until there's nothing at the coords.
  # Returns count of things gathered.
  def gather_until_none(walker, coords)
    total_count = 0
    loop do
      # Gather as many as we find, going from one silt pile to
      # another.
      count = gather_nearest_until_none
      total_count += count
      return total_count unless count > 0
      # Go back to the starting point and check again for more.
      walker.walk_to(coords)
      sleep 2
    end
    return total_count
  end

  # Just gather the nearest thing until there's nothing to gather.
  # You may wander off following the things to gather.
  def gather_nearest_until_none
    gather_count = gather_once
    if gather_count > 0
      loop do
        break unless gather_once > 0
        gather_count += 1
      end
    end
    return gather_count
  end

  # Gather the nearest thing. Return number gathered (0/1)
  def gather_once
    pb = full_screen_capture
    center = Point.new(pb.width/2, pb.height/2)
    max_rad = pb.height/2 - 200
    max_rad.times do |r|
      pts = square_with_radius(center, r)
      pts.each  do |pt|
        state = try_gather(pb, pt)
        return 1 if state == :yes
        return 0 if state == :done_here
      end
    end
    
    return 0
  end

  # Returns false if no window, or if window handled.
  # "Handle" might mean clicking on a "Pick" menu item, for example.
  # Returns true if it's a mistery window, or if it's "Too far away."
  # In either case, this method should make the window go away. 
  def check_for_post_click_window(screen_x, screen_y)
    color = getColor(screen_x, screen_y)
    if WindowGeom.isOuterBorder(color)
      AWindow.dismissAll
      return true
    else
      return false
    end
  end


  # Returns:
  # :yes - gathered silt
  # :no - Nothing at this screen point
  # :done_here - Nothing in range.  Done at these world coordinates.
  def try_gather(pb, pt)
    if click_on_this?(pb, pt)
      inv_text_before = @inventory_window.read_text
      screen_x, screen_y  = pb.to_screen(pt.x, pt.y)
      point = Point.new(screen_x, screen_y)

      # OK.  Try to gather something by clicking on it. 
      rclick_at(screen_x, screen_y, 0.2)
      sleep 0.3

      # If we got a window popup that didn't let us gather something, we're done.
      # (Gravel sometimes gives a "Scoop..." menu item. 
      if check_for_post_click_window(screen_x, screen_y)
        return :done_here
      end

      # Wait for the inventory to change.  If not, then we clicked on
      # some ground that looked like something to gather.  Let's just
      # move along.
      5.times do
        sleep 1
        inv_text = @inventory_window.read_text
        if inv_text != inv_text_before
          sleep 2.5
          return :yes
        end
      end
      return :done_here
    end

    return :no
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

end
