require 'action.rb'
require 'window'
require 'pixel_block'

class Onions < Action
  def initialize(name = "Grow onions", category = 'Plants')
    super(name, category)
  end


  # Size of a side of the square we look at to detect plants. Square
  # will be centered on your head.
  SQUARE_SIZE = 150

  def setup(parent)
    gadgets = [
      {:type => :world_loc, :label => 'Growing spot', :name => 'grow'},
      {:type => :world_loc, :label => 'Location of water', :name => 'water'},
      {:type => :point, :label => 'Drag onto your head', :name => 'head'},
      {:type => :point, :label => 'Drag onto plant button', :name => 'plant'},
      {:type => :number, :label => 'Rounds until water needed', :name => 'repeat'},
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
    @repeat = @vals['repeat'].to_i
    @grow_location = WorldLocUtils.parse_world_location(@vals['grow'])
    @water_location = WorldLocUtils.parse_world_location(@vals['water'])
    @head_rect = Rectangle.new(@vals['head.x'].to_i - SQUARE_SIZE/2, @vals['head.y'].to_i - SQUARE_SIZE/2, 
                               SQUARE_SIZE, SQUARE_SIZE)
    @plant_win = PinnableWindow.from_point(Point.new(@vals['plant.x'].to_i, @vals['plant.y'].to_i))
    @plant_point = Point.new(@plant_win.rect.width/2, @plant_win.rect.height/2)

    loop do
      walker.walk_to(@grow_location)
      sleep_sec(3)
      repeat.times do
        one_pass
      end
      walker.walk_to(@water_location)
      sleep_sec(1)
      rclick_at(225, 61) #TEMP!  Sort out ICONS
      HowMuch.new(:max)
      sleep_sec(4)
    end

  end

  def one_pass

    xhead = @vals['head.x'].to_i
    yhead = @vals['head.y'].to_i

    tiler = Tiler.new(0, 177)
    
    build_recipe = []
    6.times do 
      plant_time = Time.new
      w = plant_and_pin(build_recipe)
      tiler.tile(w)
      @threads << ControllableThread.new { tend(w, plant_time) }
      build_recipe << :r
    end
    

    @threads.each {|t| t.join}
  end

  def plant_and_pin(build_recipe)

    builder = BuildMenu.new
    before = PixelBlock.new(@head_rect)
    @plant_win.dialog_click(@plant_point)
    builder.build(build_recipe)
    after = PixelBlock.new(@head_rect)

    x = ImageUtils.brightness(ImageUtils.xor(before, after))
    insides = ImageUtils.shrink(x, 30)
    point = ImageUtils.first_non_zero(insides, 'left')

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
    sleep_sec(10 - delay)
    with_robot_lock do 
      w.refresh
      2.times { w.click_on('Water') }
    end
    sleep_sec(10)
    with_robot_lock do 
      w.refresh
      2.times { w.click_on('Water') }
    end
    sleep_sec(12)
    with_robot_lock do 
      w.refresh
      2.times { w.click_on('Water') }
    end
    sleep_sec(10)
    harvest(w)
    w.unpin
  end

  # Harvest is weird.  takes a long time to happen.  Sometimes not at
  # all the first click. Keep trying until the menu becomes empty. 
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

