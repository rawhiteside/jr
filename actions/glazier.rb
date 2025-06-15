require 'action'
require 'tempfile'
java_import org.foa.text.TextReader

class GlazierWindow < PinnableWindow
  
  GLASS_ITEMS = {
    'Make a Glass Jar' => 90,
    'Make a Glass Rod' => 60,
    'Make a Glass Pipe' => 90,
    'Make a Glass Scythe Blade' => 30,
    'Make a Sheet' => 120, 
    'Make a batch of 12 Wine Bottles' => 90,
    'Make a Decorative Torch' => 180, 
    'Make a Fine Glass Rod' => 90, 
    'Make a Fine Glass Pipe' => 90, 
  }
  attr_accessor :done, :state
  
  # The rectangle, and the point info.  GridHelper point info used for logging. 
  def initialize(rect, p)
    super(rect)
    @ix = p['ix']
    @iy = p['iy']
    @done = false
    @state = :initializing
    @start_time = Time.now
    @log_lock = JMonitor.new
  end

  # One of the two main methods.  This one:
  # - Raises temp to melting temp and melts (:max)
  # - Maintains the temperature until the "done" flag
  #   becomes true
  def tend
    log 'Tend: ------------------------ start tend'
    @state = :melt
    melt
    loop do
      break if @done
      @state = :drop
      drop
      break if @done
      @state = :rise
      rise
    end
  end

  # The other main method, called in a separate thread from the one
  # running 'tend'.
  # This one:
  # - Waits for the state variable to become :maintain.
  # - Waits for the temperature to get into the working range
  #   (1600-2400)
  # - Makes 'what' items until the amount of glass is 19.
  # - Sets the @done variable to true.
  def make_glass(what)
    log 'Make_glass: ------------------------ make_glass'
    wait_to_start_making

    # Just keep trying to click the menu.  It's not there if it's not
    # there.
    loop do
      sleep 5
      got_it = false
      with_robot_lock do
	refresh 
        temperature = data_vals[:temperature]
        if (1600..2400).cover?(temperature)
	  got_it = click_on(what)
        end
      end
      sleep(GLASS_ITEMS[what] - 10) if got_it
      break if data_vals[:glass_amount].to_s == '19'
    end

    # Wait for the final item to complete.  We'll know this when the
    # menu item reappears.
    loop do
      refresh
      break if read_text.include?(what)
      sleep 5
    end
    @done = true
  end

  def wait_to_start_making
    # Wait for melting to get done
    sleep 10 while @state != :drop
    # Wait for temp range
    loop do
      temp = data_vals[:temperature]
      break if temp > 1600 && temp < 2400
      sleep 8
    end
  end

  def data_vals
    flush_text_reader
    text = nil
    loop do
      with_robot_lock do
        refresh
        text = read_text
      end
      vals = parse_vals(text)
      return vals if vals
    end
  end

  def parse_vals(text)
    vals = {}
    # Temp
    match = Regexp.new('Temperature: ([0-9]+)').match(text)
    unless match
      puts text
      return nil
    end
    vals[:temperature] = match[1].to_i
    # Glass type
    match = Regexp.new('(.*) Glass: ').match(text)
    unless match
      puts text
      return nil
    end
    vals[:glass_type] = match[1].strip
    # Glass Amount
    match = Regexp.new('.* Glass: (.*)').match(text)
    unless match
      puts text
      return nil
    end
    vals[:glass_amount] = match[1].strip

    return vals
  end

  def temperature
    return data_vals[:temperature]
  end

  # Returns stats about the tick.
  def wait_for_tick
    orig = temperature
    sleep 5

    loop do
      current = temperature
      log "wait_for_tick: Tick check curr=#{current}, prev=#{orig}, delta=#{@last_delta}"
      if orig != current
        status = {
	  'Prev' => orig,
	  'Temperature' => current,
	  'Delta' => current - orig,
        }
        @last_delta = current - orig
        log "wait_for_tick: Temperature Changed! curr=#{current}, prev=#{orig}, last_delta=#{@last_delta}"
        return status
      else 
        sleep 5
      end
    end
  end

  def each_tick
    loop { yield(wait_for_tick) }
  end

  def melt
    glass_type = data_vals[:glass_type]
    temp_for_glass = {
      'Soda' => 3200,
      'Normal' => 3200,
      'Jewel' => 4400,
    }
    num_add = 5
    num_add = 6 if glass_type == 'Jewel'
    num_add.times {
      with_robot_lock {
        refresh
        click_on('Add 2')
      }
      wait_for_tick
    }

    # Wait for it to get hot enough.
    melt_temp = temp_for_glass[glass_type]
    each_tick {|stats| break if stats['Temperature'] > melt_temp }

    # Melt max
    # Sometimes this fails? I thing the "Into..." menu is slow to appear. 
    while data_vals[:glass_amount].to_i < 50
      with_robot_lock do
        refresh
        if click_on("Melt/Into #{glass_type}")
          HowMuch.max
        end
        AWindow.dismiss_all
      end
      sleep 1
    end
  end

  def rise
    loop do
      temp = temperature
      log "rise: done=#{@done}, temperature = #{temp}"
      with_robot_lock {
        return if @done
        refresh
        log "rise: Adding 2 cc at temperature #{temp}"
        unless click_on('Add 2')
          puts "Add 2 failed.  Trying more"
          log "rise: Add 2 failed.  Trying more"
          refresh
          refresh until click_on('Add 2')
        end
      }
      sleep 100
      log "rise checking stop. done=#{@done}, temp=#{temp}"
      break if temperature > 2050
    end
    log 'Done with rise.'
  end

  # Let temp drop till round 1750--1800
  def drop
    each_tick do |s|
      log "Drop:  temperature=#{s['Temperature']}, delta=#{@last_delta}"
      break if s['Temperature'] < 1800
      break if (s['Temperature'] + @last_delta) < 1750
      return if @done
    end
    log "Drop: done. last_delta = #{@last_delta}"
  end

  # A longer refresh delay
  def refresh
    super 0.1
  end

  def log(msg)
    @log_lock.synchronize do
      secs = "%0.1f" % (Time.now - @start_time)
      File.open("glazier-#{@ix}-#{@iy}.txt", 'a') do |f|
        f.puts("#{secs}, #{@state}, #{msg}")
      end
    end
  end

end


class Glazier < Action
  def initialize
    super('Glazier', 'Buildings')
  end

  def get_ui_vals(parent)
    choices = GlazierWindow::GLASS_ITEMS.keys
    comps = [
      {:type => :grid, :name => 'g'},
      {:type => :combo, :name => 'what', :vals => choices,
       :label => 'What do you want to make?'},
    ]
    vals = UserIO.prompt(parent, persistence_name, action_name, comps)
  end

  def setup(parent)
    @vals = get_ui_vals(parent)
  end

  def act
    tiler = Tiler.new(0, 115, 0.4)
    tiler.min_height = 400
    windows = []
    GridHelper.new(@vals, 'g').each_point do |p|
      with_robot_lock {
	w = PinnableWindow.from_screen_click(Point.new(p['x'].to_i, p['y'].to_i))
	w = GlazierWindow.new(w.get_rect, p)
	w.pin
	tiler.tile(w)
	windows << w
      }
    end

    # Start the CC-adding threads.
    windows.each do |w|
      start_worker_thread {w.tend}
    end

    # Now, start up the glass-making threads.
    make_what = @vals['what']
    windows.each do |w|
      start_worker_thread {w.make_glass(make_what)}
    end

    wait_for_worker_threads
  end
  
end

Action.add_action(Glazier.new)
