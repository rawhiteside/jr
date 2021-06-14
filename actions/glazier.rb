require 'action'
require 'tempfile'
import org.foa.text.TextReader

class GlazierWindow < PinnableWindow
  
  attr_accessor :done, :state
  
  def initialize(rect)
    super(rect)
    @done = false
    @state = :initializing
    # set_space_pixel_count(5)
  end

  # One of the two main methods.  This one:
  # - Raises temp to melting temp and melts (:max)
  # - Maintains the temperature until the "done" flag
  #   becomes true
  def tend
    @state = :melt
    melt
    @state = :maintain
    loop do
      break if @done
      drop
      break if @done
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
    wait_to_start_making

    # Just keep trying to click the menu.  It's not there if it's not
    # there.
    loop do
      sleep 3
      got_it = false
      with_robot_lock do
	refresh
        temperature = data_vals[:temperature]
        if (1600..2400).cover?(temperature)
	  got_it = click_on(what)
        end
      end
      sleep 60 if got_it
      break if data_vals[:glass_amount].to_s == '19'

      # Wait for menu to appear again, indicating that the last thing
      # we made is done.
      #
      # When you add cc, this item can appear (bogusly).  Let's make
      # sure we see it two consecutive times before declaring things
      # all done.
      count = 0
      loop_done = false
      until loop_done do
        sleep 3
        text = nil
        with_robot_lock do
          refresh
          text = read_text
        end

        if text.index(what)
          count += 1
        else
          count = 0
        end
        loop_done = (count >= 2)
      end
    end
    @done = true
  end

  def wait_to_start_making
    # Wait for melting to get done
    sleep 4 while @state != :maintain
    # Wait for temp range
    loop do
      temp = data_vals[:temperature]
      break if temp > 1600 && temp < 2400
      sleep 5
    end
  end

  def data_vals
    flush_text_reader
    text = nil
    with_robot_lock do
      refresh
      text = read_text
      check_text text
    end
    vals = {}
    # Temp
    match = Regexp.new('Temperature: ([0-9]+)').match(text)
    puts text unless match

    vals[:temperature] = match[1].to_i
    # Glass type
    match = Regexp.new('(.*) Glass: ').match(text)
    puts text unless match
    vals[:glass_type] = match[1].strip
    # Glass Amount
    match = Regexp.new('.* Glass: (.*)').match(text)
    puts text unless match
    vals[:glass_amount] = match[1].strip
    # CC
    match = Regexp.new('Charcoal Avail: ([0-9]+)').match(text)
    puts text unless match
    vals[:cc] = match[1].to_i if match 
    # XXX

    return vals
  end

  def temperature
    return data_vals[:temperature]
  end

  # Returns stats about the tick.
  def wait_for_tick
    start = Time.now
    orig = temperature

    loop do
      sleep 4
      current = temperature
      if orig != current
        status = {
	  'Prev' => orig,
	  'Temperature' => current,
	  'Delta' => current - orig,
	  'Time' => Time.now - start,
        }
        @last_delta = current - orig
        # XXX log "Tick curr=#{current}, prev=#{orig}, delta=#{@last_delta}"
        return status
      end
    end
  end

  def each_tick
    loop {yield(wait_for_tick)}
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
      log "Rise done=#{@done}"
      with_robot_lock {
        return if @done
        refresh
        click_on('Add 2')
      }
      sleep 100
      log "Rise checking stop. done=#{@done}, temp=#{temperature}"
      break if temperature > 2050
    end
  end

  # Let temp drop till round 1750--1800
  def drop
    each_tick do |s|
      log "Drop  temperature=#{s['Temperature']}, delta=#{@last_delta}"
      break if s['Temperature'] < 1800
      break if (s['Temperature'] + @last_delta) < 1750
      return if @done
    end
  end

  def log(s)
    # puts s

  end

end


class Glazier < Action
  def initialize
    super('Glazier', 'Buildings')
  end

  def get_ui_vals(parent)
    choices = [
      'Make a Glass Jar',
      'Make a Glass Rod',
      'Make a Glass Pipe',
      'Make a Glass Scythe Blade',
      'Make a Sheet', 
      'Make a batch of 12 Wine Bottles',
      'Make a Decorative Torch', 
      'Make a Fine Glass Rod', 
      'Make a Fine Glass Pipe', 
    ]
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
    tiler = Tiler.new(0, 115)
    tiler.min_height = 400
    windows = []
    GridHelper.new(@vals, 'g').each_point do |p|
      with_robot_lock {
	w = PinnableWindow.from_screen_click(Point.new(p['x'].to_i, p['y'].to_i))
	w = GlazierWindow.new(w.get_rect)
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
