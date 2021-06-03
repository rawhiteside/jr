require 'action'
require 'square_with_radius'
# 
# A super class for gathering stuff:  silt, gravel, dig stones...
# Main entry is "gather_until_done".
# 
# You must implement gather_color?(pb, x, y) which tells if it's the
# right color.  This will be called by click_on_this?, which you might
# want to override
# 
# You might also need to override check_for_post_click_window
class PickThings < Action
  def initialize(name, category)
    super(name, category)
    # Path we get dragged along while harvesting at a point. 
    @drag_path = []
    # 
    # After the item appears in inventory, there's still an animation
    # before it disapears from the scene.  This is the delay required
    # so that we dont' click on it again.  Set it from your subclass. 
    @post_gather_wait = 0.5
  end


  # Gather nearby things repeatedly, just wandering wherever it takes
  # you. When you run out of things, return to these coords and do it
  # again.  Repeat *that* until there's nothing at the coords.
  # Returns count of things gathered.
  def gather_until_none(walker, coords, inventory_window)
    total_count = 0
    loop do
      # Gather as many as we find, going from one silt pile to
      # another.
      @drag_path = [coords]
      count = gather_nearest_until_none(inventory_window)
      total_count += count
      return total_count unless count > 0
      # Go back to the starting point and check again for more.
      walker.walk_path(@drag_path.reverse)
      walker.post_walk_pause
    end
    return total_count
  end

  # Just gather the nearest thing until there's nothing to gather.
  # You may wander off following the things to gather.
  def gather_nearest_until_none(inventory_window)
    gather_count = gather_once(inventory_window)
    if gather_count > 0
      loop do
        break unless gather_once(inventory_window) > 0
        update_drag_path
        gather_count += 1
      end
    end
    return gather_count
  end

  # Called for each successful gather.  Keep a list of coordinates we
  # get dragged to, so can return back.
  #
  # Needed for papyrus, since we can get stuck easily. 
  def update_drag_path
    curr = ClockLocWindow.instance.coords.to_a
    @drag_path << curr unless curr == @drag_path.last
  end

  # Gather the nearest thing. Return number gathered (0/1)
  def gather_once(inventory_window)
    pb = full_screen_capture
    center = Point.new(pb.width/2, pb.height/2)
    max_rad = pb.height/2 - 200
    max_rad.times do |r|
      pts = SquareWithRadius.square_with_radius(center, r)
      skip_next = false
      pts.each  do |pt|
        if skip_next
          skip_next = false
          next
        end
        state = try_gather(pb, pt, inventory_window)
        return 1 if state == :yes
        return 0 if state == :done_here
        skip_next = true if state == :no_and_skip
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
    # PinnableWindowGeom
    if LegacyWindowGeom.isOuterBorder(color)
      AWindow.dismissAll
      return true
    else
      return false
    end
  end

  def click_on_this?(pb, pt)
    gather_color?(pb, pt.x, pt.y) &&
      gather_color?(pb, pt.x + 1, pt.y) &&
      gather_color?(pb, pt.x - 1, pt.y) &&
      gather_color?(pb, pt.x, pt.y + 1) &&
      gather_color?(pb, pt.x, pt.y - 1)
  end

  # Returns:
  # :yes - gathered something.
  # :no - Nothing at this screen point
  # :done_here - Nothing in range.  Done at these world coordinates.
  # :no_and_skip - Nothing here, and skip the next possibility. 
  def try_gather(pb, pt, inventory_window)
    #
    # If the central point fails, then the next point cannot possibly
    # succeed, so skip it.
    unless gather_color?(pb, pt.x, pt.y)
      return :no_and_skip
    end

    if click_on_this?(pb, pt)
      inv_text_before = inventory_window.read_text
      screen_x, screen_y  = pb.to_screen(pt.x, pt.y)
      point = Point.new(screen_x, screen_y)

      # OK.  Try to gather something by clicking on it. 
      rclick_at(screen_x, screen_y, 0.2)
      sleep 0.2

      # If we got a window popup that didn't let us gather something, we're done.
      # (Gravel sometimes gives a "Scoop..." menu item. 
      if check_for_post_click_window(screen_x, screen_y)
        return :done_here
      end


      # Wait for the inventory to change.  If not, then we clicked on
      # some ground that looked like something to gather.  Let's just
      # move along.
      5.times do
        sleep 0.4
        inv_text = inventory_window.read_text
        if inv_text != inv_text_before
          sleep @post_gather_wait
          return :yes
        end
      end
      return :done_here
    end

    return :no
  end


end
