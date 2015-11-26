require 'action'

class WaterMineAction < Action
  def initialize
    super('Water mine', 'Buildings')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :name => 'water-mine', :label => 'Water mine'},
      {:type => :number, :name => 'scan-interval', :label => 'Angle scan interval (min)'},
    ]
    @vals = UserIO.prompt(parent, 'water-mine', 'Water mine', gadgets)

  end

  def stop
    @water_mine.log_action('Stop')
    super
  end

  def act
    pt = point_from_hash(@vals, 'water-mine')
    win = PinnableWindow.from_point(pt)
    interval_minutes = @vals['scan-interval'].to_i

    @water_mine = WaterMineWorker.new(win, interval_minutes * 60)

    loop do
      @water_mine.tend
      sleep_sec(30)
    end
  end
end

class WaterMineWorker
  LOG_FILE = 'water-mine.csv'
  WIND_INTERVAL = 60 * 118
  POST_WIND_WAIT = 60 * 10
  def initialize(w, scan_interval)
    @win = w
    @last_wind_time = nil
    log_action('Start')
    @scan_interval = scan_interval
    @scan_gems = 0
  end

  def start_scan
    @scan_angle = angle
    @scan_start = Time.now
    @scan_gems = 0
  end

  def scan_angle
    return if (Time.now - @last_wind_time) < POST_WIND_WAIT

    # Have we started scanning?
    if @scan_angle.nil?
      start_scan
      return
    end

    # Look at things after the scan interval
    if (Time.now - @scan_start) > @scan_interval
      # If no gems, go to the next angle and try again.
      set_angle(@scan_angle + 1) if @scan_gems == 0
      start_scan
    end
    
  end

  def set_angle(ang)
    ang = 10 if ang > 30
    @win.refresh
    @win.click_on("Set/Angle of #{ang}")
    log_action("Pitch angle #{ang}")
  end

  def angle
    text = @win.read_text
    Regexp.new('Pitch Angle is ([0-9]+)').match(text)[1].to_i
  end
    
  def wind
    @last_wind_time = Time.new
    @win.click_on('Wind', 'lc')
    log_action('Wind')
  end

  def tend
    @win.refresh
    @angle = angle

    @win.refresh
    wind if @last_wind_time.nil? || ((Time.new - @last_wind_time) > WIND_INTERVAL)

    ARobot.new.sleep_sec(0.2)
    @win.refresh
    take

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
    label = @win.read_text.split("\n")[1]

    edate = etime = ''
    begin
      edate = ClockLocWindow.instance.date
      etime = ClockLocWindow.instance.time.delete(' ')
    rescue Exception => e
    end
    t = Time.now.to_s.split(' ')
    wdate = t[0]
    wtime = t[1]
    File.open(LOG_FILE, 'a') do |f|
      f.puts("#{label}, #{wdate}, #{wtime}, #{edate}, #{etime}, #{@angle}, #{action}")
    end
    
  end
end

Action.add_action(WaterMineAction.new)
