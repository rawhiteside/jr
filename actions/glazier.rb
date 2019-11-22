require 'action'
import org.foa.text.TextReader

# Has states:
# :melt, :cool, :make, :done
class GlazierWindow < PinnableWindow
  
  LOGGING = true
  
  MELT_CC_FOR_GLASS_TYPE = {
    'Soda' => 6,
    'Normal' => 6,
    'Jewel' => 7,
  }

  TEMP_FOR_GLASS_TYPE = {
    'Soda' => 3200,
    'Normal' => 3200,
    'Jewel' => 4400,
  }

  attr_accessor :state
  
  def initialize(rect, make_what, index)
    super(rect)
    # These used in the logging messages.
    @index = index
    @tick_count = 0
    @ticks_since_add = 0

    @state = :melt
    @melt_count = 0
    @tick_data = nil
    @make_what = make_what
  end

  # The main method.  Expects to be called repeatedly. Look at the
  # state of the window, and decide what to do.
  def tend
    @tick = tick?

    # Are we melting the glass?
    if @state == :melt
      # changes state to :cool when it's added all the cc, and melted the glass
      melt 
      return
    end
    
    # Cooling down from the melt.
    if @state == :cool
      cooling_check if @tick
      return if @state == :cool
    end

    # Making stuffs!!
    if @state == :make
      make
    end
    
  end

  def make
    if data_vals[:glass_amount] <= 19
      @state = :done
    end

    temp = @tick_data[:temperature]
      
    # Make it if it's there.
    refresh
    if (1600..2400).cover?(temp)
      refresh if click_on(@make_what)
    end
    return unless @tick
    # 
    # Tend the temperature.
    delta = @tick_data[:delta]
    return unless delta < 0
    #
    # It *may* be that we added cc last tick, but not in time.  The
    # temp dropped gain. We should not addd CC in that case
    return if @ticks_since_add < 2
    
    # Drop in temp.
    if temp < 1950
      click_on('Add 12')
      @ticks_since_add = 0
    elsif temp < 2100
      click_on('Add 6')
      @ticks_since_add = 0
    elsif temp < 2200
      click_on('Add 2')
      @ticks_since_add = 0
    end
  end

  # Advances state to :make if we're in the zone.
  def cooling_check
    return unless @tick
    return if @tick_data[:temperature] > 2400
    @state = :make
  end

  # Heat up the bench and melt glass.
  def melt
    # First time
    if @melt_count == 0
      click_on('Add 2')
      @melt_count += 1
      return
    end
    # 
    # Otherwise, only do things on a tick.
    return unless @tick

    if @melt_count < MELT_CC_FOR_GLASS_TYPE[@tick_data[:glass_type]]
      click_on('Add 2')
      @melt_count += 1
      return
    end

    # OK, all the CC has been added.  Wait for temp
    if @tick_data[:temperature] > TEMP_FOR_GLASS_TYPE[@tick_data[:glass_type]] 
      # If there's somehow already 50 glass in there, then we don't have
      # to add any.
      #
      # (Didn't do the expeeriment to see if clicking the "Melt" button
      # in that case caused trouble.)
      if data_vals[:glass_amount] >= 50
        @state = :cool
        return
      end

      # Melt the glass.
      if click_on("Melt/Into #{@tick_data[:glass_type]}")
        HowMuch.max
        AWindow.dismiss_all
        # We're done here.
        @state = :cool
      end
    end
  end

  
  # Read the window, and decide if there's been a tick.  If so, update @data
  def tick?
    # Hash with the data from the window.
    dv = data_vals
    #
    # First call
    if @tick_data.nil?
      @tick_data = dv
      return false
    end
    # 
    # Temperature tick?
    if @tick_data[:temperature] == dv[:temperature]
      return false
    else
      dv[:delta] = dv[:temperature] - @tick_data[:temperature]
      @tick_data = dv
      @tick_count += 1
      @ticks_since_add += 1
      log dv.to_s + ", @state = #{@state}"
      return true
    end
  end

  def click_on(what)
    log what
    super(what)
  end


  DATA_HEIGHT = 107
  def text_rectangle
    rect = super
    rect.height -= DATA_HEIGHT

    rect
  end

  def data_text_reader
    TextReader.new(data_rect, self)
  end

  def read_data
    text = nil
    3.times do
      refresh
      text = data_text_reader.read_text

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
    match = Regexp.new('Temperature[ :]+([0-9]+)').match(text)
    vals[:temperature] = match[1].to_i
    # Glass type
    match = Regexp.new('(.*) Glass[ :]+').match(text)
    vals[:glass_type] = match[1].strip
    # Glass Amount
    match = Regexp.new('.* Glass[ :]+(.*)').match(text)
    vals[:glass_amount] = match[1].strip.to_i
    # CC
    match = Regexp.new('Charcoal.*: ([0-9]+)').match(text)
    vals[:cc] = match[1].to_i if match 

    return vals
  end


  def log(s)
    puts "#{@index}, %04d, #{s}" % [@tick_count] if LOGGING
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
    vals = UserIO.prompt(parent, persistence_name, action_name, comps)
  end

  def setup(parent)
    @vals = get_ui_vals(parent)
  end

  def act
    tiler = Tiler.new(0, 115)
    tiler.min_height = 400
    windows = []
    index = 0
    make_what = @vals['what']
    GridHelper.new(@vals, 'g').each_point do |p|
      with_robot_lock {
	w = PinnableWindow.from_screen_click(Point.new(p['x'].to_i, p['y'].to_i))
	w = GlazierWindow.new(w.get_rect, make_what, index)
        index += 1
	w.pin
	tiler.tile(w)
	windows << w
      }
    end

    make_what = @vals['what']
    loop do
      break if windows.size == 0

      live_windows = []
      windows.each do |w|
        w.tend
        live_windows << w unless w.state == :done
      end
      windows = live_windows
    end
  end
end

Action.add_action(Glazier.new)
