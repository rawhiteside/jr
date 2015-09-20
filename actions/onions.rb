require 'action.rb'
require 'window'
require 'pixel_block'

class Onions < Action
  def initialize(name = "Grow onions", category = 'Plants')
    super(name, category)
  end

  VEGETABLE_DATA = {
    "Cabbage/Mut's Fruition/(1)" => {:water => 1},
    "Cabbage/Bastet's Yielding/(2)" => {:water => 2},

    "Carrots/Osiris's Orange/(1)" => {:water => 1},
    "Carrots/Osiris'Green Leaf/(2)" => {:water => 2},

    "Garlic/Apep's Crop/(2)" => {:water => 2},
    "Garlic/Heket's Reaping/(1)" => {:water => 1},

    "Leeks/Horus' Grain/(2- 3 waters!)" => {:water => 3, :max_plant => 6},
    "Leeks/Hapi's Harvest/(1)" => {:water => 1},

    "Onions/Amun's Bounty/(1)" => {:water => 1},
    'Onions/Tears of Sinai/(2)' => {:water => 2},
  }

  # Size of a side of the square we look at to detect plants. Square
  # will be centered on your head.
  SQUARE_SIZE = 450

  def setup(parent)
    gadgets = [
      {:type => :combo, :label => 'What to grow?:', :name => 'veggie', 
       :vals => VEGETABLE_DATA.keys.sort},
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
    @vegi_name = @vals['veggie'].split('/')[1].strip
    @vegi_data = VEGETABLE_DATA[@vals['veggie']]
    @repeat = @vals['repeat'].to_i
    @grow_location = WorldLocUtils.parse_world_location(@vals['grow'])
    @water_location = WorldLocUtils.parse_world_location(@vals['water'])
    @head_rect = Rectangle.new(@vals['head.x'].to_i - SQUARE_SIZE/2, @vals['head.y'].to_i - SQUARE_SIZE/2, 
                               SQUARE_SIZE, SQUARE_SIZE)
    @plant_win = PinnableWindow.from_point(Point.new(@vals['plant.x'].to_i, @vals['plant.y'].to_i))
    @plant_point = Point.new(@plant_win.rect.width/2, @plant_win.rect.height/2)

    max_plants = @vegi_data[:max_plant] || 20
    puts "Max plants : #{max_plants}"

    loop do
      walker.walk_to(@grow_location)
      sleep_sec(3)
      repeat.times do
        one_pass(max_plants)
      end
      walker.walk_to(@water_location)
      sleep_sec(1)
      rclick_at(225, 61) #TEMP!  Sort out ICONS
      HowMuch.new(:max)
      sleep_sec(4)
    end

  end

  def one_pass(max_plants)

    xhead = @vals['head.x'].to_i
    yhead = @vals['head.y'].to_i

    # Needs to be down below the build menu.
    tiler = Tiler.new(0, 190)
    plant_count = 0
    
    build_recipe = [:w, :w]
    5.times do |plant_number|
      break if plant_count >= max_plants
      plant_count += 1
      w, plant_time = plant_and_pin(build_recipe, 'left')
      tiler.tile(w)
      @threads << ControllableThread.new { tend(w, plant_number, plant_time) }
      build_recipe << :r
    end

    build_recipe = [:e, :e]
    5.times do |plant_number|
      break if plant_count >= max_plants
      plant_count += 1
      w, plant_time = plant_and_pin(build_recipe, 'right')
      tiler.tile(w)
      @threads << ControllableThread.new { tend(w, plant_number, plant_time) }
      build_recipe << :r
    end
    

    @threads.each {|t| t.join}
  end

  MAGIC_THRESHOLD = 40
  def plant_and_pin(build_recipe, search_dir)

    builder = BuildMenu.new
    before = PixelBlock.new(@head_rect)
    @plant_win.dialog_click(@plant_point)
    builder.build(build_recipe)
    plant_time = Time.new
    after = PixelBlock.new(@head_rect)

    x = ImageUtils.brightness(ImageUtils.xor(before, after))
    
    insides = ImageUtils.shrink(x, MAGIC_THRESHOLD)
    point = ImageUtils.first_non_zero(insides, search_dir)

    spoint = insides.to_screen(point)

    w = PinnableWindow.from_screen_click(spoint)
    w.pin

    return w, plant_time
  end
  
  def tend(w, plant_number, plant_time)
    # Times in sec (relative to plant time) at which to water.
    # 
    # Fiddling with these.  Added 3 sec to what I actualy measured.  I
    # think I was watering too soon, for some reason.
    # grow_times = [0, 15, 30, 45] # measured.
    grow_times = [0, 18, 33, 45]
    harvest_time = 45
    3.times do |index|
      target_secs = grow_times[index] + (grow_times[index+1] - grow_times[index])/2
      delta = (Time.new - plant_time)
      delay = target_secs - delta
      sleep_sec(delay)
      with_robot_lock do 
        # puts "plant #{plant_number} watering #{index} at time #{(Time.new - plant_time)}"
        w.refresh
        @vegi_data[:water].times do
          unless w.click_on('Water')
            puts "plant #{plant_number} watering #{index} failed."
          end
          sleep_sec(0.075) # Magic!!  Added when leeks failed.
        end
      end
    end
    sleep_sec(harvest_time - (Time.new - plant_time))

    harvest_and_unpin(w)
  end

  # Harvest is weird.  takes a long time to happen.  Sometimes not at
  # all the first click. Keep trying until the menu becomes empty. 
  def harvest_and_unpin(w)
    loop do
      with_robot_lock do
        w.refresh

        # Click on harvest if it's there, but don't stop.
        w.click_on('Harvest')

        # If the menu goes empty, then w're done.
        if w.read_text.size == 0
          w.unpin
          break
        end
      end

      sleep_sec(3)
    end
  end
end



Action.add_action(Onions.new)

                 
