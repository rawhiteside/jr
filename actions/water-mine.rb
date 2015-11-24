require 'action'

class WaterMineAction < Action
  def initialize
    super('Water mine', 'Buildings')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :name => 'water-mine', :label => 'Water mine'},
    ]
    @vals = UserIO.prompt(parent, 'water-mine', 'Water mine', gadgets)

  end

  def stop
    @water_mine.log_action('Stop')
  end

  def act
    pt = point_from_hash(@vals, 'water-mine')
    win = PinnableWindow.from_point(pt)
    @water_mine = WaterMineWorker.new(win)
    loop do
      @water_mine.tend
      sleep_sec(50)
    end
  end
end

class WaterMineWorker
  LOG_FILE = 'water-mine.csv'
  WIND_INTERVAL = 50 * 120
  def initialize(w)
    @win = w
    @last_wind_time = nil
    log_action('Start')
  end

  def tend
    if @last_wind_time.nil? || ((Time.new - @last_wind_time) > WIND_INTERVAL)
      @last_wind_time = Time.new
      @win.click_on('Wind', 'lc')
      log_action('Wind')
    end
    @win.refresh
    ARobot.new.sleep_sec(0.2)
    if @win.click_on('Take')
      match = Regexp.new('Take the (.*)').match(@win.read_text)
      log_action(match[1])
    end
  end

  
  def log_action(action)
    text = @win.read_text
    label = text.split("\n")[1]

    pitch = Regexp.new('Pitch Angle is ([0-9]+)').match(text)[1]

    edate = ClockLocWindow.instance.date
    etime = ClockLocWindow.instance.time.delete(' ')
    t = Time.now.to_s.split(' ')
    wdate = t[0]
    wtime = t[1]
    File.open(LOG_FILE, 'a') do |f|
      f.puts("#{label}, #{wdate}, #{wtime}, #{edate}, #{etime}, #{pitch}, #{action}")
    end
    
  end
end

Action.add_action(WaterMineAction.new)
