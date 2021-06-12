require 'action'
require 'window'

class Walker < ARobot

  @@listener_added = nil

  # Key here is [targetx <=> currx, targety <=> currx]
  # Corresponding value is a direction, as in :nw
  DIRECTION_MAP = {
    [0, 0] => :done, 
    [1, 0] => :e, 
    [-1, 0] => :w, 
    [0, 1] => :n, 
    [0, -1] => :s, 
    [1, 1] => :ne, 
    [1, -1] => :se, 
    [-1, 1] => :nw, 
    [-1, -1] => :sw, 
  }

  # Keys that make us walk in the provided direction.
  DIR_KEYS = {
    :n => [VK_UP],
    :s => [VK_DOWN],
    :w => [VK_LEFT],
    :e => [VK_RIGHT],
    :ne => [VK_UP, VK_RIGHT],
    :nw => [VK_UP, VK_LEFT],
    :se => [VK_DOWN, VK_RIGHT],
    :sw => [VK_DOWN, VK_LEFT],
  }

  def initialize(stuck_watch = nil)
    super()
    @stuck_watch = (!stuck_watch.nil?)
    
    # Directions to try going if we get stuck. 
    # We try one, then rotate the array. 
    @unstick_directions = DIR_KEYS.keys

    # So we stop walking on pause. 
    unless @@listener_added
      # Button up is not guarded by the lock.
      # Ooops. This listener never gets removed.  Oh well....
      l = Proc.new { |running| if !running then all_up end }
      RobotPauser.instance.add_pause_listener(l)
      @@listener_added = true
    end
  end

  
  # After we "stop" walking, animation continues for a bit.  This
  # pause will get past that.
  POST_WALK_PAUSE = 0.25

  # Time for the key to be down for a good "step"
  KEY_DELAY=0.15

  # Time for the key to be down for a big "step"
  KEY_DELAY_BIG=0.25

  # Time necessary for the walk animation to complete.
  STEP_DELAY = 0.0


  def left_big(delay = KEY_DELAY_BIG)
    send_vk(VK_LEFT, delay); sleep STEP_DELAY
  end
  def right_big(delay = KEY_DELAY_BIG)
    send_vk(VK_RIGHT, delay); sleep STEP_DELAY
  end
  def up_big(delay = KEY_DELAY_BIG)
    send_vk(VK_UP, delay); sleep STEP_DELAY
  end
  def down_big(delay = KEY_DELAY_BIG)
    send_vk(VK_DOWN, delay); sleep STEP_DELAY
  end

  def left(delay = KEY_DELAY)
    send_vk(VK_LEFT, delay); sleep STEP_DELAY
    send_vk(VK_LEFT, delay); sleep STEP_DELAY
  end
  alias west left

  def right(delay = KEY_DELAY)
    send_vk(VK_RIGHT, delay); sleep STEP_DELAY
  end
  alias east right

  def up(delay = KEY_DELAY)
    send_vk(VK_UP, delay); sleep STEP_DELAY
    send_vk(VK_UP, delay); sleep STEP_DELAY
  end
  alias north up

  def down(delay = KEY_DELAY)
    send_vk(VK_DOWN, delay); sleep STEP_DELAY
    send_vk(VK_DOWN, delay); sleep STEP_DELAY
  end
  alias south down

  # An array whose elements are :left, :right, :up, or :down
  def steps(recipe, delay = KEY_DELAY)
    recipe.each {|dir| step(dir, delay) }
  end

  def step(dir, delay = KEY_DELAY)
    self.send dir
  end


  # dir is one of :n, :s, :w, :e, :ne, :nw, :se, :sw
  def start_going(dir)
    all_up
    DIR_KEYS[dir].each {|k| key_press(k, 0)}
  end

  def all_up
    [VK_LEFT, VK_UP, VK_DOWN, VK_RIGHT].each {|k| key_release(k, 0)}
  end

  def stop_going
    all_up
  end

  def post_walk_pause
    sleep POST_WALK_PAUSE
  end

  # +coords+: a set of coordinates through which to walk in order.
  # Provide a block, if you want something done at each point.
  # If that block returns :stop, then stop
  def walk_path(coords)
    coords.each do |xy|
      walk_to(xy)
      if block_given?
	return :stop if yield == :stop
      end
    end
  end

  # +coords+: a set of coordinates through which to walk.
  # +repeat+ : the number of times to repeat.
  # Provide a block, if you want something done when you get there.
  # Block can return :stop to abort the walking
  def walk_loop(coords, repeat = 1)
    repeat.times do
      coords.each do|xy|
	walk_to(xy)
	if block_given?
	  return :stop if yield  == :stop 
	end
      end
    end
  end

  # +coords+: a set of coordinates through which to walk.  These are
  # processed forwrd, then backward each repeat
  # +repeat+ : the number of times to repeat.
  # 
  # Provide a block, if you want something done when you get there.
  # Block can return :stop to abort the walking
  def walk_back_and_forth(coords, repeat = 1)
    coords = coords.dup
    skip_it = false
    repeat.times do
      coords.each do |xy|
	# Contortions so we don't visit the endpoints twice.
	if skip_it
	  skip_it = false
	  next
	end
	walk_to(xy)
	if block_given?
	  return :stop if yield == :stop 
	end
      end
      coords.reverse!
      skip_it = true
    end
  end

  # Walk from current location to the provided coordinates
  # Target coords are as [x,y]


  SHORT_DISTANCE = 3
  def walk_to(target)
    # If it's a long ways, walk to intermediate waypoints along the
    # direction.
    loop do
      curr = ClockLocWindow.instance.coords.to_a
      if (distance(curr, target).round < SHORT_DISTANCE)
        walk_to_nearby(target)
        return
      else
        walk_to_nearby(find_waypoint(target, SHORT_DISTANCE))
      end
    end
  end

  def distance(pt1, pt2)
    Math.sqrt((pt1[0] - pt2[0])**2 + (pt1[1] - pt2[1]) **2)
  end

  # Find a point +dist+ way along a line towards +target+
  def find_waypoint(target, dist)
    curr = ClockLocWindow.instance.coords.to_a
    dist = distance(curr, target)
    fract = SHORT_DISTANCE/dist
    deltax = ((target[0] - curr[0]) * fract).round
    deltay = ((target[1] - curr[1]) * fract).round
    return [curr[0] + deltax, curr[1] + deltay]
  end

  def walk_to_nearby(target)
    # Count pases though the loc-walker loop.  We refresh the keys
    # every refresh_count passes.  Thus, in case of a wild r-click,
    # it'll start back going.
    refresh_count = 2
    count = 0

    # Loop that watches the loc window, and adjusts direction
    # accordingly.
    curr_direction = nil
    check_for_stuck(nil)
    loop do
      check_for_pause
      count += 1
      curr = ClockLocWindow.instance.coords.to_a

      key = [target[0] <=> curr[0], target[1] <=> curr[1]]
      direction = DIRECTION_MAP[key]
      # Maybe we're done.
      if direction == :done
	stop_going
	return 
      end
      # Change directions?
      if (count % refresh_count) == 0 || direction != curr_direction
	start_going(direction)
	curr_direction = direction
      end
      check_for_stuck(curr)
      sleep 0.1
    end
  end

  # *****************************************************************
  # Try to deal with getting stuck.
  # 
  # If coords don't change in this many seconds, we're stuck. 
  STUCK_SECONDS = 4

  # Stuck handler.  If we stay at the same coords too long, try
  # walking in some direction for a bit, and hope we get out of
  # trouble.
  # 
  # Give it the current coords each time we read them during walk_to.
  # Give nil to reset it (at the start of walk_to).
  def check_for_stuck(coords)
    return unless @stuck_watch
    # 
    # Reset the stuck-checker
    if coords.nil?
      @prev_time = @prev_coords = nil
      return
    end
    # First non-nil coords?
    if @prev_coords.nil? 
      @prev_coords = coords
      @prev_time = Time.now
      return
    end
    # .. Maybe everything's OK:
    if coords != @prev_coords
      @prev_coords = coords
      @prev_time = Time.now
      return
    end
    # Coords the same as last time.  Maybe it's been a short time.
    return if (Time.now - @prev_time) < STUCK_SECONDS
    # 
    # Ooops.  We're stuck.  Try to handle.
    handle_stuck
    @prev_time = @prev_coords = nil
  end
  #
  # We're stuck.  Try to just walk in some direction and hope that
  # clears things up.
  def handle_stuck
    all_up
    dir = @unstick_directions[0]
    @unstick_directions.rotate!
    puts "We're stuck.  trying to go #{dir} for a second"
    start_going(dir)
    sleep 1
    all_up
  end
end

