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
  def initialize()
    super()
    @center_y = 502
    @center_x = 641
    @offset = 100
    
    # So we stop walking on pause. 
    unless @@listener_added
      # Button up is not guarded by the lock.
      # Ooops. This listener never gets removed.  Oh well....
      l = Proc.new { |running| if !running then all_up end }
      RobotPauser.instance.add_pause_listener(l)
      @@listener_added = true
    end
  end

  
  # Time for the key to be down for a good "step"
  KEY_DELAY=0.075

  # Time necessary for the walk animation to complete.
  STEP_DELAY = 0.2


  def left(delay = KEY_DELAY)
    send_vk(VK_LEFT, delay); sleep_sec STEP_DELAY
    send_vk(VK_LEFT, delay); sleep_sec STEP_DELAY
  end
  alias west left

  def right(delay = KEY_DELAY)
    send_vk(VK_RIGHT, delay); sleep_sec STEP_DELAY
    send_vk(VK_RIGHT, delay); sleep_sec STEP_DELAY
  end
  alias east right

  def up(delay = KEY_DELAY)
    send_vk(VK_UP, delay); sleep_sec STEP_DELAY
    send_vk(VK_UP, delay); sleep_sec STEP_DELAY
  end
  alias north up

  def down(delay = KEY_DELAY)
    send_vk(VK_DOWN, delay); sleep_sec STEP_DELAY
    send_vk(VK_DOWN, delay); sleep_sec STEP_DELAY
  end
  alias south down

  # An array whose elements are :left, :right, :up, or :down
  def steps(recipe, delay = KEY_DELAY)
    recipe.each {|dir| step(dir, delay) }
  end

  def step(dir, delay = KEY_DELAY)
    self.send dir
  end


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
  def walk_to(target)
    # Count pases though the loc-walker loop.  We refresh the keys
    # every refresh_count passes.  Thus, in case of a wild r-click,
    # it'll start back going.
    refresh_count = 2
    count = 0

    # Loop that watches the loc window, and adjusts direction
    # accordingly.
    curr_direction = nil
    loop do
      ControllableThread.check_for_pause
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
      sleep_sec 0.3
    end
  end
end

