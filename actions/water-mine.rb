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
      sleep_sec(gem_delay)
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
      set_angle(angle - 1)
      @win.refresh
      start_scan
    end
    
  end

  def set_angle(ang)
    ang = 10 if ang > 30
    ang = 30 if ang < 10
    @win.refresh
    @win.click_on("Set/Angle of #{ang}")
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
    sleep 0.1
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
      f.puts('longitude, latitude, (real) time, angle, event') if action == 'Start'
      f.puts("#{coords[0]}, #{coords[1]}, #{wtime}, #{@angle}, #{action}")
    end
    
  end
end

Action.add_action(WaterMineAction.new)
