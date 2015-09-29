require 'action'
require 'walker'
require 'jmonitor'

class JugCount
  attr_reader :count
  attr_reader :lock
  def initialize(num)
    @count = @max = num
    @lock = JMonitor.new
  end

  def used_one
    @lock.synchronize {@count -= 1}
  end

  def used(n)
    @lock.synchronize {@count -= n}
  end

  def refill
    @lock.synchronize {@count = @max}
  end

end

class CasualClay < Action
  attr_accessor :jug_count
  def initialize
    super('Casual Clay', 'Gather')
    @jug_count = nil
  end

  def act
    pixel = 0x4f0503
    xy = [95, 102]
    loop do
      got_pixel = get_pixel(xy[0], xy[1])
      if pixel == got_pixel
	rclick_at(*xy)
	@jug_count.used_one if @jug_count
	sleep_sec 0.5
      else
	sleep_sec 0.01
      end
    end
  end
end

class Clay < Action
  def initialize(name = 'Clay', group = 'Gather')
    super(name, group)
    @threads = []
    @loop = [
      [4523, -5872], 
      [4518, -5872], 
    ]
  end

  def start_clay_watcher
    gatherer =  CasualClay.new
    gatherer.jug_count = @jug_count
    @threads << ControllableThread.new { gatherer.act }
  end


  def setup(parent)
    comps = [
      {:type => :point, :name => 'chest', :label => 'Stash chest window'},
      {:type => :world_loc, :name => 'chest-coords', :label => 'Coordinates within reach of the chest.'},
      {:type => :world_loc, :name => 'water-coords', :label => 'Coordinates with water.'},
      {:type => :number, :name => 'jug_count', :label => 'How many jugs? '},
      {:type => :world_path, :label => 'Path to walk', :name => 'path'}
    ]
    @vals = UserIO.prompt(parent, 'Clay', 'Clay', comps)

    @vals
  end
  
  def act
    stash_window = PinnableWindow.from_point(point_from_hash(@vals, 'chest'))
    count = @vals['jug_count'].to_i
    @jug_count = JugCount.new(count)
    path = WorldLocUtils.parse_world_path(@vals['path'])
    chest_coords = WorldLocUtils.parse_world_location(@vals['chest-coords'])
    water_coords = WorldLocUtils.parse_world_location(@vals['water-coords'])

    walker = Walker.new
    walker.walk_to(path[0])
    start_clay_watcher
    loop do
      walker.walk_loop(path, 99999999) do
	if @jug_count.count < 25
	  walker.walk_to(chest_coords)
	  HowMuch.new(:max) if stash_window.click_on('Stash/Clay')
	  HowMuch.new(:max) if stash_window.click_on('Stash/Flint')
	  walker.walk_to(water_coords)
	  refill
	end
      end
    end
      
  end

  def refill
    with_robot_lock do
      @jug_count.lock.synchronize do
	sleep_sec 0.5
	rclick_at(144, 98)
	sleep_sec 0.2
	HowMuch.new(:max)
	@jug_count.refill
	sleep_sec 0.1
      end
    end
  end

  def stop
    @threads.each {|t| t.kill}
    super
  end
end

class BackAndForthClay < Clay
  def initialize
    super('Clay (Back and forth)', 'Gather')
    @stash_loc = [4523, -5866]
    @gather_loc = [4515, -5874]
  end

  def gather
    pixel = 0xe2967e
    xy = [230, 110]
    if pixel == get_pixel(*xy)
      rclick_at(*xy)
      # Wait for the pixel to change.
      Thread.pass until pixel != get_pixel(*xy)
      return true
    else
      Thread.pass
      return false
    end
  end

  def act
    loop do
      @walker.walk_to(@gather_loc)
      count = @jug_count.count - 2
      keys = [VK_UP, VK_DOWN]
      count.times do
	key_release(keys[0])
	key_press(keys[1])
	loop do
	  break if gather
	end
	keys = keys.reverse
      end

      @walker.walk_to(@stash_loc)
      gather
      HowMuch.new(:max) if @stash_window.click_on('Stash/Clay')
      HowMuch.new(:max) if @stash_window.click_on('Stash/Flint')
      refill
    end
      
  end

end


Action.add_action(BackAndForthClay.new)
Action.add_action(Clay.new)
Action.add_action(CasualClay.new)
