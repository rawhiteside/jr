require 'action.rb'
require 'window'
require 'pixel_block'

class Onions < Action
  def initialize(name = "Grow onions", category = 'Plants')
    super(name, category)
  end


  # Size of a side of the square we look at to detect plants. Square
  # will be centered on your head.
  SQUARE_SIZE = 200

  def setup(parent)
    gadgets = [
      {:type => :world_loc, :label => 'Growing spot', :name => 'grow'},
      {:type => :world_loc, :label => 'Location of water', :name => 'water'},
      {:type => :point, :label => 'Drag onto your head', :name => 'head'},
      {:type => :point, :label => 'Drag onto plant button', :name => 'plant'},
    ]
    @vals =  UserIO.prompt(parent, 'onions', 'onions', gadgets)
    @threads = []
  end

  def stop
    @threads.each {|t| t.kill} if @threads
    super
  end

  def act
    walker = Walker.new
    @grow_location = WorldLocUtils.parse_world_location(@vals['grow'])
    @water_location = WorldLocUtils.parse_world_location(@vals['water'])
    @head_rect = Rectangle.new(@vals['head.x'].to_i - SQUARE_SIZE/2, @vals['head.y'].to_i - SQUARE_SIZE/2, 
                               SQUARE_SIZE, SQUARE_SIZE)
    @plant_win = PinnableWindow.from_point(Point.new(@vals['plant.x'].to_i, @vals['plant.y'].to_i))
    @plant_point = Point.new(@plant_win.rect.width/2, @plant_win.rect.height/2)

    loop do
      walker.walk_to(@grow_location)
      sleep_sec(2)
      one_pass
      sleep_sec(4)
      walker.walk_to(@water_location)
      rclick_at(225, 61) #TEMP!  Sort out ICONS
      HowMuch.new(:max)
      sleep_sec(4)
    end

  end

  WALK_DELAY = 0.35
  def one_pass

    xhead = @vals['head.x'].to_i
    yhead = @vals['head.y'].to_i

    tiler = Tiler.new(0, 77, 0)
    offsets = [[100, 0], 
               [0, -60],
               [-80, 0],
               [-80, 0],
#               [-30, 80],
              ]
    
    plant_time = Time.new
    w = plant_and_pin
    tiler.tile(w)
    @threads << ControllableThread.new { tend(w, plant_time) }

    offsets.each do |xy_off|
      lclick_at(xhead + xy_off[0], yhead + xy_off[1], 0.02)
      sleep_sec(WALK_DELAY) # animation
      plant_time = Time.new
      w = plant_and_pin
      tiler.tile(w)
      @threads << ControllableThread.new { tend(w, plant_time) }
    end

    @threads.each {|t| t.join}
  end

  def plant_and_pin

    before = PixelBlock.new(@head_rect)
    @plant_win.dialog_click(@plant_point)
    after = PixelBlock.new(@head_rect)

    x = ImageUtils.xor(before, after)
    insides = ImageUtils.shrink(x)
    point = ImageUtils.first_non_zero(insides, 'top')

    spoint = insides.to_screen(point)

    w = PinnableWindow.from_screen_click(spoint)
    w.pin

    w
  end
  
  def tend(w, plant_time)
    recipe = [
      10, 'Water', 'Water',
      10, 'Water', 'Water',
      12, 'Water', 'Water',
      15, 'Harvest',
    ]
    now = Time.new
    delay = now - plant_time
    remaining = 
    sleep_sec(10 - delay)
    2.times { w.refresh; w.click_on('Water') }
    sleep_sec(10)
    2.times { w.refresh; w.click_on('Water') }
    sleep_sec(12)
    2.times { w.refresh; w.click_on('Water') }
    sleep_sec(10)
    harvest(w)
    w.unpin
  end

  # Harvest is weird.  takes a long time to happen.  Sometimes not at
  # all the first click. Keep trying until the menu mecomes empty. 
  def harvest(w)
    loop do
      w.refresh
      # Click on harvest if it's there, but don't stop.
      w.click_on('Harvest')

      # If the menu goes empty, then w're done.
      break if w.read_text.size == 0

      sleep_sec(3)
    end
  end
end



Action.add_action(Onions.new)

