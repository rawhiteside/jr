require 'action'

class WaterMineAction < Action
  def initialize
    super('Water mine', 'Buildings')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :name => 'water-mine', :label => 'Water mine'},
      {:type => :number, :name => 'check-freq', :label => 'Gem check interval (seconds)'},
      {:type => :number, :name => 'scan-interval', :label => 'Angle scan interval (minutes)'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)

  end

  def stop
    @water_mine.log_action('Stop') if @water_mine
    super
  end

  def act
    pt = point_from_hash(@vals, 'water-mine')
    win = PinnableWindow.from_point(pt)
    gem_delay = @vals['check-freq'].to_i
    interval_minutes1 = @vals['scan-interval'].to_i

    @water_mine = WaterMineWorker.new(win, interval_minutes1 * 60)

    loop do
      @water_mine.tend
      sleep(gem_delay)
    end
  end
end

class WaterMineWorker
  LOG_FILE = 'water-mine.csv'
  WIND_INTERVAL = 60 * 118   # Seconds
  POST_WIND_WAIT = 60 * 5    # Seconds

  # We start at some angle.
  # Watch the mine for interval-1 seconds.
  # - If no gems, the advance to next angle. Else stay here and continue

  def initialize(w, scan_interval)
    @pitch_list = nil
    @past_pitches = []
    @win = w
    @win.default_refresh_loc = 'lc'
    @last_wind_time = nil
    log_action('Start')
    @scan_interval = scan_interval
    @scan_gems = 0
    @angle = "unknown"
    @wind_delay = 0
  end

  def start_scan
    @scan_start = Time.now
    @scan_gems = 0
    @wind_delay = 0
    set_pitch_list unless @pitch_list
  end

  # If the label looks like "String, num, num..." then the numbers are
  # the pitches to scan.
  def set_pitch_list
    text = @win.read_text
    return unless text
    label = text.split(/\n/)[3]
    if label=~ /-+/
      label = "Unlabeled"
    end
    words = label.split(',')
    nums = []
    tag = words.shift
    all_nums = words.size > 0
    words.each do |word|
      num = word.strip.to_i
      if num == 0
        all_nums = false
        break
      end
      nums << num
    end
    # Is it a pitch list?
    if all_nums
      @pitch_list = nums
      @mine_tag = tag
    else
      @pitch_list = []
      @mine_tag = tag
      10.upto(30) {|i| @pitch_list << i}
    end

    advance_angle
  end

  def scan_angle
    return if (Time.now - @last_wind_time) < POST_WIND_WAIT

    # Have we started scanning?
    if @scan_start.nil?
      start_scan
      return
    end

    # Look at things after the scan interval
    if (Time.now - @scan_start) > (@scan_interval + @wind_delay)
      log_action("Gems last #{@scan_interval} seconds, #{@scan_gems}")
      advance_angle
      @win.refresh
      start_scan
    end
    
  end

  def advance_angle
    if @pitch_list.size > 0
      ang = @pitch_list.shift
      @past_pitches << ang
    else
      @pitch_list = @past_pitches
      ang = @pitch_list.shift
      @past_pitches = [ang]
    end
    ang = 10 if ang > 30
    ang = 30 if ang < 10
    @win.refresh
    @win.click_on("Set/Angle of #{ang}") if ang != angle
    @win.refresh
    log_action("Pitch angle #{ang}")
  end

  def angle
    @win.refresh
    text = @win.read_text
    match = Regexp.new('Pitch Angle is ([0-9]+)').match(text)
    if match 
      return match[1].to_i
    else
      puts "Failed to find angle in: #{text}"
      # Return some number.
      return 18
    end

  end
    
  def wind
    @last_wind_time = Time.new
    @win.click_on('Wind', 'lc')
    log_action('Wind')
    # Dead time after winding.
    @wind_delay = POST_WIND_WAIT
  end

  def tend
    @win.refresh
    set_pitch_list if @pitch_list.nil?
    # Seems to be slow to update the menu.
    sleep 0.3
    take
    @angle = angle

    # Time to wind again?
    wind if @last_wind_time.nil? || ((Time.new - @last_wind_time) > WIND_INTERVAL)

    scan_angle
  end

  def take
    if @win.click_on('Take')
      @scan_gems += 1
      match = Regexp.new('Take the (.*)').match(@win.read_text)
      log_action(match[1])
    end
  end
  
  def log_action(action)
    t = Time.now.to_s.split(' ')
    coords = ClockLocWindow.instance.coords.to_a
    wtime = t[1]
    File.open(LOG_FILE, 'a') do |f|
      f.puts('mine tag, (real) time, angle, event') if action == 'Start'
      f.puts("#{@mine_tag}, #{wtime}, #{@angle}, #{action}")
    end
    
  end
end

Action.add_action(WaterMineAction.new)
