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
        sleep_sec(0.1)
      end
      while w.click_on('Grill')
	HowMuch.max
        w.refresh
        sleep_sec(0.1)
      end
      w.refresh('lc') while w.click_on('Place', 'lc')

      w.refresh
      sleep_sec(0.1)
      if w.click_on('Take./Limestone')
        HowMuch.amount(4)
      end

      puts 'unpin'
      w.unpin
      sleep_sec 0.5
    end
  end

  def act
    task = @vals['task']
    load_firepits if task == 'Load'
    burn_firepits if task =~ /Burn/
    light_firepits if task == 'Light'
    tend_firepits if task == 'Tend'
  end


  def burn_firepits
    light_firepits
    tend_firepits
  end
  
  def light_firepits

    # Light the fires.
    GridHelper.new(@vals, 'g').each_point do |p|
      w = PinnableWindow.from_screen_click(Point.new(p['x'], p['y']))
      w.pin
      while w.click_on('Strike')
        w.refresh

        if w.click_on('Remove Tinder') 
          w.refresh
        end

        if w.click_on('Place Tinder')
          w.refresh
        end
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
    @threads.each {|t| t.join}
  end
end

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
  end

  def tend
    @tick = 0
    loop do
      @tick += 1
      ControllableThread.check_for_pause
      new_state = get_new_firepit_state
      if new_state == HOT
	with_robot_lock do
	  mm(@x, @y)
	  sleep_sec 0.2
	  send_string('s')
	end
      end
      sleep_sec 0.5
    end
  end

  BRIGHT = 450
  def get_white_fraction
    x = @x - 10
    y = @y - 10
    size = 40
    pixels = nil
    with_robot_lock {
      pixels = screen_rectangle(x, y, size, size)
    }
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
    puts "tick #{@tick}: Frac: #{frac} White: #{white_count}, Bright: #{bright_count}\n" if @ix == 0 && @iy == 0
    return frac
  end

  
  HOT_THRESH = 0.15
  NORMAL_THRESH = 0.05
  NORMAL = 'normal'
  HOT = 'hot'
  # 
  # Returns a new firepit state: one of "hot", "normal"
  # Returns nil if state did not change
  def get_new_firepit_state
    frac = get_white_fraction
    # During startup.
    if frac == nil || @state == nil
      if @state == NORMAL
	return nil
      else
	return @state = NORMAL
      end
    end
    # We enter "hot", it we're in "normal" and this is the
    # second consecutive tick of high fraction
    if frac >= HOT_THRESH
      @hot_count += 1
      @normal_count = 0
      return @state = HOT if @state != HOT && @hot_count > 1
      return nil
    elsif frac < NORMAL_THRESH
      @normal_count += 1
      @hot_count = 0
      return @state = NORMAL if @state != NORMAL && @normal_count > 1
      return nil
    else
      @normal_count = @hot_count = 0
      return nil
    end
    
    
  end

end

Action.add_action(Firepits.new)
