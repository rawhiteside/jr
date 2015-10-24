require 'action'
require 'user-io'

class Wheat < Action
  def initialize
    super('Wheat', 'Plants')
  end

  def setup(parent)
    gadgets = [
      {:type => :world_loc, :name => 'grow_loc', :label => 'NW corner of the growing region', },
      {:type => :number, :name => 'rows', :label => 'Number of rows', },
      {:type => :number, :name => 'cols', :label => 'Number of colums', },
      {:type => :world_loc, :name => 'water_loc', :label => 'Location near water', }, 
      {:type => :world_loc, :name => 'stash_loc', :label => 'Location near stash chest', }, 
      {:type => :point , :name => 'stash_win', :label => 'Pinned stash window', }, 
      {:type => :point , :name => 'plant_win', :label => 'Pinned plant window', }, 
    ]
    @vals = UserIO.prompt(parent, 'wheat', 'Wheat', gadgets)
  end

  def act
    read_vals
    tiler = Tiler.new(160, 70)
    tiler.y_offset = 30
    @threads = []
    thread_info = {}
    @row_count.times do |yoff|
      @col_count.times do |xoff|
        plant_loc = [@start_loc[0] + xoff, @start_loc[1] + yoff]
        goto_plant_loc(plant_loc)
        w = plant_and_pin
        tiler.tile(w)
        screen_rect = w.rect
        thread = ControllableThread.new { tend(w) }
        @threads << thread
        thread_info[thread] = {'plant_loc' => plant_loc, 'win_rect' => screen_rect}
      end
    end
    center = [@start_loc[0] + @col_count/2, @start_loc[1] + @row_count/2]
    @walker.walk_to(center)

    @threads.each {|t| t.join}
  end

  def stop
    @threads.each {|t| t.kill} if @threads
    super
  end
          
  def tend(w)
    loop do
      sleep_sec(3)
      with_robot_lock do
        w.refresh
        if w.read_text == ''
          w.unpin
          return
        end
        decrement_jugs if w.click_on('Water')
        w.click_on('Harvest')
      end
    end
  end

  def decrement_jugs
  end

  def goto_plant_loc(loc)
    way = [loc[0] - 1, loc[1] + 1]
    @walker.walk_to(way)
    @walker.walk_to(loc)
    sleep_sec(0.3)
  end
  
  def plant_and_pin
    ss = screen_size
    center_rect = Rectangle.new(ss.width/2 - 100, ss.height/2-100, 200, 200)
    before = PixelBlock.new(center_rect)
    r = @plant_win.rect
    @plant_win.dialog_click(Point.new(r.width/2, r.height/2))
    sleep_sec(0.5)
    after =  PixelBlock.new(center_rect)
    xor = ImageUtils.xor(before, after)
    target = ImageUtils.find_largest(ImageUtils.brightness(xor), 'top', 20)
    win = PinnableWindow.from_screen_click(xor.to_screen(target))
    win.pin
    return win
  end
  
  def read_vals
    @start_loc = WorldLocUtils.parse_world_location(@vals['grow_loc'])
    @water_loc = WorldLocUtils.parse_world_location(@vals['water_loc'])
    @stash_loc = WorldLocUtils.parse_world_location(@vals['stash_loc'])
    @row_count = @vals['rows'].to_i
    @col_count = @vals['cols'].to_i
    @stash_win = PinnableWindow.from_point(point_from_hash(@vals, 'stash_win'))
    @plant_win = PinnableWindow.from_point(point_from_hash(@vals, 'plant_win'))
    @walker = Walker.new
  end

end

Action.add_action(Wheat.new)

