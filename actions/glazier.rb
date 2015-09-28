require 'action'
import org.foa.text.TextReader

class GlazierWindow < PinnableWindow
  
  attr_accessor :done, :state
  
  def initialize(rect)
    super(rect)
    @done = false
    @state = :initializing
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
    # there
    loop do
      sleep_sec 3
      got_it = false
      with_robot_lock do
	refresh
	got_it = click_on(what)
      end
      sleep_sec 60 if got_it
      break if data_vals[:glass_amount].to_s == '19'
    end

    # Wait for menu to appear again, indicating that the last thing we
    # made is done.
    #
    # When you add cc, this item can appear (bogusly).  Let's make
    # sure we see it two conscutive before declaring things all done.
    count = 0
    loop_done = false
    until loop_done do

      sleep_sec 6

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
    @done = true
  end

  def wait_to_start_making
    # Wait for melting to get done
    sleep_sec 4 while @state != :maintain
    # Wait for temp range
    loop do
      temp = data_vals[:temperature]
      break if temp > 1600 && temp < 2400
      sleep_sec 5
    end
  end

  DATA_HEIGHT = 107

  def text_rectangle
    rect = super
    rect.height -= DATA_HEIGHT

    rect
  end

  def data_text_reader
    TextReader.new(data_rect)
  end

  def read_data
    text = nil
    3.times do
      with_robot_lock do
        refresh
        text = data_text_reader.read_text
      end

      return text if !text.nil? && text =~ /Charcoal/ && text =~ /Temperature/

      puts 'Glazier: retrying read_data'
      sleep_sec(2)
    end

    text
  end

  def data_rect
    rect = text_rectangle
    # Move in this far from left and right. 
    off = 20

    Rectangle.new(rect.x + off, rect.y + rect.height + 1,
		  rect.width - (2 * off), DATA_HEIGHT)
  end

  def data_vals
    text = read_data
    
    vals = {}
    # Temp
    match = Regexp.new('Temperature: ([0-9]+)').match(text)
    vals[:temperature] = match[1].to_i
    # Glass type
    match = Regexp.new('(.*) Glass:').match(text)
    vals[:glass_type] = match[1].strip
    # Glass Amount
    match = Regexp.new('.* Glass:(.*)').match(text)
    vals[:glass_amount] = match[1].strip
    # CC
    match = Regexp.new('Charcoal Avail: ([0-9]+)').match(text)
    vals[:cc] = match[1].to_i if match 

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
      sleep_sec 4
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
    with_robot_lock do
      refresh
      click_on("Melt/Into #{glass_type}")
      HowMuch.new(:max)
      AWindow.dismiss_all
    end
  end

  def watch
    each_tick do |stats|
      p stats
      return if temperature == 0
    end
  end
  
  def rise
    loop do
      log "Rise done=#{@done}"
      return if @done
      with_robot_lock {
	refresh
	click_on('Add 2')
      }
      sleep_sec 100
      log "Rise checking stop. done=#{@done}, temp=#{temperature}"
      break if temperature > 2050
    end
  end

  # Let temp drop till round 1750--1800
  def drop
    each_tick do |s|
      log "Drop  temperature=@{s['Temperature']}, delta=#{@last_delta}"
      break if s['Temperature'] < 1800
      break if (s['Temperature'] + @last_delta) < 1750
    end
  end

  def log(s)
    # puts s
  end
end


class Glazier < Action
  def initialize(n)
    super(n, 'Buildings')
    @threads = []
  end

  def stop
    @threads.each {|t| t.kill} if @threads
    super
  end

  def get_ui_vals(parent)
    choices = [
      'Make a Glass Jar',
      'Make a Glass Rod',
      'Make a Glass Pipe',
      'Make a Glass Blade',
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
    vals = UserIO.prompt(parent, 'Glazier', 'Glazier', comps)
  end

  def setup(parent)
    @vals = get_ui_vals(parent)
  end

  def act
    tiler = Tiler.new(0, 30, 0.45)
    @threads = []
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
      @threads << ControllableThread.new {w.tend}
    end

    # Now, start up the glass-making threads.
    make_what = @vals['what']
    windows.each do |w|
      @threads << ControllableThread.new {w.make_glass(make_what)}
    end

    @threads.each {|t| t.join}
  end
  
end

Action.add_action(Glazier.new('Glazier'))
