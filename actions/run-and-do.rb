require 'action'
require 'walker'

class RunAndDo < Action
  def initialize
    super('Run and do', 'Misc')
  end

  def persistence_name
    'run_and_do'
  end

  def setup(parent)
    gadgets = [
      {:type => :world_path, :label => 'Path to walk.', :name => 'path',
       :rows => 20,
       :aux => ['Apiary', 'Greenhouse']},
#      {:type => :point, :name => 'storage', :label => 'Drag to pinned bonfire or storage'},


#      {:type => :point, :name => 'water-mine-1', :label => 'Water mine 1'},
#      {:type => :point, :name => 'water-mine-2', :label => 'Water mine 2'},
#      {:type => :point, :name => 'water-mine-3', :label => 'Water mine 3'},
#      {:type => :number, :name => 'scan-interval-1', :label => 'WM2: Angle scan interval 1 (minutes)'},
#      {:type => :number, :name => 'scan-interval-2', :label => 'WM2: Angle scan interval 2 (minutes)'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def stop
    @mine_worker1.log_action('Stop') if @mine_worker1
    @mine_worker2.log_action('Stop') if @mine_worker2
    @mine_worker3.log_action('Stop') if @mine_worker3
    super
  end

  def init_stuff
    path_text = @vals['path']

    if path_text.include?('Stash')
      @storage = PinnableWindow.from_point(point_from_hash(@vals, 'storage'))
    end

#    @mine_worker1 = nil
#    if path_text.include? 'Water Mine 1'
#      water_mine = PinnableWindow.from_point(point_from_hash(@vals, 'water-mine-1'))
#      scan_interval_1 = @vals['scan-interval-1'].to_i
#      scan_interval_2 = @vals['scan-interval-2'].to_i
#      @mine_worker1 = WaterMineWorker.new(water_mine, scan_interval_1 * 60, scan_interval_2 * 60)
#    end
#
#    @mine_worker2 = nil
#    if path_text.include? 'Water Mine 2'
#      water_mine = PinnableWindow.from_point(point_from_hash(@vals, 'water-mine-2'))
#      scan_interval_1 = @vals['scan-interval-1'].to_i
#      scan_interval_2 = @vals['scan-interval-2'].to_i
#      @mine_worker2 = WaterMineWorker.new(water_mine, scan_interval_1 * 60, scan_interval_2 * 60)
#    end
#
#    @mine_worker3 = nil
#    if path_text.include? 'Water Mine 3'
#      water_mine = PinnableWindow.from_point(point_from_hash(@vals, 'water-mine-3'))
#      scan_interval_1 = @vals['scan-interval-1'].to_i
#      scan_interval_2 = @vals['scan-interval-2'].to_i
#      @mine_worker3 = WaterMineWorker.new(water_mine, scan_interval_1 * 60, scan_interval_2 * 60)
#    end

    @coords = WorldLocUtils.parse_world_path(@vals['path'])

    true
  end

  def act
    return unless init_stuff

    walker = Walker.new
    @coords.each do |c|
      if c.kind_of? Array
        walker.walk_to(c)
      #        elsif c == 'Water Mine 1'
      #          @mine_worker1.tend
      #        elsif c == 'Water Mine 2'
      #          @mine_worker2.tend
      #        elsif c == 'Water Mine 3'
      #          @mine_worker3.tend
      elsif c == 'Greenhouse'
        harvest_greenhouse
      elsif c == 'Storage Stash'
        storage_stash(@storage)
      elsif c == 'Apiary'
        apiary
      end
    end
  end

  def apiary
    sleep(0.5)
    pb = full_screen_capture
    color_min = Color.new(75, 61, 62)
    color_max = Color.new(80, 68, 72)
    pb_apiary = PixelBlock.load_image('patches/Stardew.png')
    point = pb.find_patch(pb_apiary)
    if point
      with_robot_lock do
        mm(point, 0.1)
        sleep 1 # xxx
        # xxx send_string('tc')
        popup = PopupWindow.find
        if popup
          popup.dismiss
        end
      end
    else
      puts "No apiary found."
    end
  end

  # Just spam "H" near the center of the screen.  Should be standing
  # in the GH, and the whole area is active.
  def harvest_greenhouse
    dim = screen_size
    sleep_sec 0.1
    mm(dim.width/2, dim.height/2 + 100)
    sleep_sec 0.1
    send_string 'h'
    sleep_sec 0.1
    mm(dim.width/2, dim.height/2 - 100)
    sleep_sec 0.1
    send_string 'h'
    sleep_sec 0.1
  end
  
  def storage_stash(storage)
    storage.refresh
    sleep 0.2
    HowMuch.max if storage.click_on('Stash./Wood')
    storage.click_on('Stash./Insect/All')
  end
end

Action.add_action(RunAndDo.new)

