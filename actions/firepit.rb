require 'action'
require 'window'

class Firepits < Action
  def initialize
    super('Firepits', 'Buildings')
    @threads = []
  end

  def setup(parent)
    gadgets = [
      {:type => :grid, :name => 'g', :label => 'Show me the grid of firepits.'},
      {:type => :combo, :name => 'task', :label => 'What should I do?',
       :vals => ['Load', 'Burn (light and tend)', 'Light', 'Tend']
      }
    ]

    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def stop
    @threads.each {|t| t.kill} if @threads
    super
  end

  def load_firepits
    # Fill up each firepit
    GridHelper.new(@vals, 'g').each_point do |p|
      pt = Point.new(p['x'], p['y'])
      w = PinnableWindow.from_screen_click(pt)
      w.pin
      while w.click_on('Add')
	HowMuch.max
        w.refresh
        sleep(0.1)
      end
      while w.click_on('Grill')
	HowMuch.max
        w.refresh
        sleep(0.1)
      end
      w.refresh('lc') while w.click_on('Place', 'lc')

      w.refresh
      sleep(0.1)
      if w.click_on('Take./Limestone')
        HowMuch.amount(4)
      end

      w.unpin
      sleep 0.5
    end
  end

  def act
    task = @vals['task']
    if task == 'Load'
      load_firepits 
      return
    end
    return unless scan_clickpoints
    burn_firepits if task =~ /Burn/
    light_firepits if task == 'Light'
    tend_firepits if task == 'Tend'

    @threads.each {|t| t.join}
  end


  def burn_firepits
    # Forks off threads to tend.
    tend_firepits
    # We'll try to light while the tender is running. 
    light_firepits
  end
  
  # Firepits have unclickable holes in them.  Make sure they're all OK
  # before we do anything else.
  def scan_clickpoints

    # Check the fires.
    GridHelper.new(@vals, 'g').each_point do |p|
      w = PinnableWindow.from_screen_click(Point.new(p['x'], p['y']))
      return nil unless w
      dismiss_all
    end
    return true
  end
  
  def light_firepits

    # Light the fires.
    GridHelper.new(@vals, 'g').each_point do |p|
      w = nil
      # Bracket all this, so it doesn't interfere with screen shots. 
      with_robot_lock do
        w = PinnableWindow.from_screen_click(Point.new(p['x'], p['y']))
        w.pin
        w.drag_to(Point.new(200, 200))
      end

      until w.read_text =~ /merrily/
        w.refresh
        w.click_on('Strike')
        sleep 2
        w.refresh
        w.click_on('Place Tinder')
        sleep 0.5
      end

      w.unpin
    end
  end


  def tend_firepits
    # Watch the burning pits and stoke as appropriate
    GridHelper.new(@vals, 'g').each_point do |p|
      f = Firepit.new(p)
      @threads << ControllableThread.new {f.tend}
    end
  end
end

# Holds the robot lock during screenshots, so popped windows don't
# interfere.
class Firepit < ARobot
  def initialize(p)
    super()
    @x = p['x'].to_i
    @y = p['y'].to_i
    @ix = p['ix']
    @iy = p['iy']
    @state = nil
    @hot_count = 0
    @normal_count = 0
    @start_time = Time.now
  end

  def log_stoke(stoke)
    log_msg('0,,,') if (stoke == 1)
    log_msg("#{stoke},,,")
    log_msg('0,,,') if (stoke == 1)
  end

  def log_data(bright, white, frac)
    log_msg(",#{bright},#{white},#{frac}")
  end

  def log_msg(msg)
    secs = Time.now - @start_time
    File.open("firepit-#{@ix}-#{@iy}.csv", 'a') do |f|
      f.puts("#{secs},#{@state},#{@normal_count},#{@hot_count},#{msg}")
    end
  end
  
  def tend
    @tick = 0
    loop do
      @tick += 1
      check_for_pause
      new_state = get_new_firepit_state
      if new_state == HOT
        # Tried: move twice to loc w 0.05 sleep around the
        # moves. Nope.

        # Tried: Add 0.15 sleep after mouse move.
        # -- better.  Still lost pits

        # Tried 0.2 -- no better.

        # OK,  Use menus.
        
        
	with_robot_lock do
          w = PinnableWindow.from_screen_click(@x, @y)
          if w
            unless w.click_on 'Stoke'
              puts 'Failed to click on stoke'
              log_stoke 'Failed to click on stoke'
              puts w.read_text
              dismiss_all
            end
          end

        end
        log_stoke(1)
        sleep 5
      else
        log_stoke(0)
      end
      sleep 1
    end
  end

  BRIGHT = 450
  IMAGE_SIZE = 40
  def get_white_fraction
    x = @x - IMAGE_SIZE/2
    y = @y - IMAGE_SIZE/2
    pixels = nil
    #
    # To keep the fire-starting windows from messing this up.
    with_robot_lock do
      pixels = screen_rectangle(x, y, IMAGE_SIZE, IMAGE_SIZE)
    end
    bright_count = 0
    white_count = 0
    pixels.height.times do |y|
      pixels.width.times do |x|
	color = pixels.color(x, y)
	r, g, b = color.red, color.green, color.blue
	bright_count += 1 if r + g + b >= BRIGHT
	white_count += 1 if r == 0xFF && g == 0xFF && b == 0xFF
      end
    end
    frac = nil
    frac = white_count.to_f / bright_count.to_f unless bright_count == 0
    log_data(bright_count, white_count, frac)
    return frac
  end

  
  HOT_THRESH = 0.15
  NORMAL_THRESH = 0.05
  NORMAL = 'normal'
  HOT = 'hot'
  REPEATS = 3
  # 
  # Returns a new firepit state: one of "hot", "normal"
  # Returns nil if state did not change
  def get_new_firepit_state
    frac = get_white_fraction
    # Frac is nil if there are no bright spots at all. This happens
    # (apart from startup) when heavy lag causes the fire to vanish
    # for a few moments.  We just ignore these states entirely.
    return nil unless frac

    # We're just getting going. Start in "normal" state.
    return @state = NORMAL if @state == nil

    # We enter "hot", if we're in "normal" and this is the
    # REPEATS consecutive tick of high fraction
    if frac >= HOT_THRESH
      @hot_count += 1
      @normal_count = 0
      return @state = HOT if @state != HOT && @hot_count > REPEATS
      return nil
    elsif frac < NORMAL_THRESH
      @normal_count += 1
      @hot_count = 0
      return @state = NORMAL if @state != NORMAL && @normal_count > REPEATS
      return nil
    else
      @normal_count = @hot_count = 0
      return nil
    end
    
    
  end

end

Action.add_action(Firepits.new)
