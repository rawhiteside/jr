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

  def act
    pt = point_from_hash(@vals, 'water-mine')
    water_mine = WaterMine.new(pt)
    loop do
      water_mine.tend
      sleep_sec(50)
    end
  end
end

class WaterMine
  WIND_INTERVAL = 50 * 60
  def initialize(pt)
    @win = PinnableWindow.from_point(pt)
    @last_wind_time = nil
  end

  def tend
    if @last_wind_time.nil? || ((Time.new - @last_wind_time) > WIND_INTERVAL)
      puts 'winding'
      @last_wind_time = Time.new
      @win.click_on('Wind', 'lc')
    end
    @win.refresh
    puts 'checking for take'
    @win.click_on('Take')
  end
end

Action.add_action(WaterMineAction.new)
