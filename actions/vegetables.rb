require 'action.rb'
require 'window'

class Onions < Action
  def initialize(name = "Grow vegetables", category = 'Plants')
    super(name, category)
    @threads = []
  end

  VEGETABLE_DATA = {
    "Cabbage/Mut's Fruition/(1)" => {:water => 1,
                                     :left_build_init => [:l,:l],
                                    },
    "Cabbage/Bastet's Yielding/(2)" => {:water => 2,
                                        :left_build_init => [:l,:l],
                                       },
    
    "Carrots/Osiris's Orange/(1)" => {:water => 1,
#                                      :build_incr_fac => 2,
#                                      :right_build_init => [:L,]*2
                                     },
    "Carrots/Osiris'Green Leaf/(2)" => {:water => 2,
#                                        :build_incr_fac => 2,
#                                        :right_build_init => [:L,]*2
                                       },


    "Garlic/Apep's Crop/(2)" => {:water => 2,
                                },
    "Garlic/Heket's Reaping/(1)" => {:water => 1,
                                    },


    "Leeks/Horus' Grain/(2- 3 waters!)" => {:water => 3,
#                                            :build_incr_fac => 3,
                                           },
    "Leeks/Hapi's Harvest/(1)" => {:water => 1, 
#                                   :build_incr_fac => 2,
                                  },

    "Onions/Amun's Bounty/(1)" => {:water => 1,
                                  },
    'Onions/Tears of Sinai/(2)' => {:water => 2,
                                   },
  }

  # Size of a side of the square we look at to detect plants. Square
  # will be centered on your head.
  SQUARE_SIZE = 200

  # The distance out that Jaby's arm reaches from the center of her
  # head.  Actually, picking up is larger.  Using this value for now. 
  REACH_RADIUS = 40

  def setup(parent)
    gadgets = [
      {:type => :combo, :label => 'What to grow?:', :name => 'veggie', 
       :vals => VEGETABLE_DATA.keys.sort},
      {:type => :world_loc, :label => 'Growing spot', :name => 'grow'},
      {:type => :world_loc, :label => 'Location of water', :name => 'water'},
      {:type => :point, :label => 'Drag onto your head', :name => 'head'},
      {:type => :point, :label => 'Drag onto plant button', :name => 'plant'},
      {:type => :number, :label => 'Rounds until water needed', :name => 'repeat'},
      {:type => :number, :label => 'Number of beds.', :name => 'beds'},
      {:type => :number, :label => 'Second water (~15-30).', :name => 'second'},
      {:type => :number, :label => 'Third water (~30-45).', :name => 'third'},
    ]
    @vals =  UserIO.prompt(parent, 'onions', 'onions', gadgets)
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
    @head_rect = Rectangle.new(@vals['head.x'].to_i - SQUARE_SIZE/2,
                               @vals['head.y'].to_i - SQUARE_SIZE/2, 
                               SQUARE_SIZE, SQUARE_SIZE)
    @plant_win = PinnableWindow.from_point(Point.new(@vals['plant.x'].to_i, @vals['plant.y'].to_i))
    @plant_point = Point.new(@plant_win.rect.width/2, @plant_win.rect.height/2)

    beds = @vals['beds'].to_i

    loop do
      walker.walk_to(@grow_location)
      walker.up
      walker.down
      sleep_sec(1)
      repeat.times do
        one_pass(beds)
      end
      walker.walk_to(@water_location)
      sleep_sec(1)
      rclick_at(225, 61) #TEMP!  Sort out ICONS
      HowMuch.new(:max)
      sleep_sec(3)
    end

  end

  def one_pass(max_plants)

    xhead = @vals['head.x'].to_i
    yhead = @vals['head.y'].to_i

    # Needs to be down below the build menu.
    tiler = Tiler.new(0, 190)
    tiler.y_offset = 20
    plant_count = 0
    
    build_base = [:w, :w]
    extra = @vegi_data[:left_build_init]
    if extra
      extra.each {|elt| build_base << elt }
    end
    build_incr_list = [:r, :l, [:r]*2, [:l]*2, [:r]*3, [:l]*3, ]
    num_left = @vegi_data[:num_left] || 6
    build_incr_fac = @vegi_data[:build_incr_fac] || 1

    build_recipe = ([] << build_base).flatten
    num_left.times do |index|
      break if plant_count >= max_plants
      plant_count += 1
      w, plant_time = plant_and_pin(build_recipe, 'left')
      build_recipe = ([] << build_base << [build_incr_list[index]] * build_incr_fac).flatten

      # If we missed it, plow ahead.
      next unless w
      #puts "***Tiling #{plant_count}"
      tiler.tile(w)
      #puts "***done tiling #{plant_count}"
      @threads << ControllableThread.new { tend(w, plant_count, plant_time) }
    end

    build_base = [:e, :e]
    extra = @vegi_data[:right_build_init]
    if extra
      extra.each {|elt| build_base << elt }
    end

    num_right = @vegi_data[:num_right] || 6
    build_recipe = ([] << build_base).flatten
    num_right.times do |index|
      break if plant_count >= max_plants
      plant_count += 1
      w, plant_time = plant_and_pin(build_recipe, 'right')
      build_recipe = ([] << build_base << [build_incr_list[index]] * build_incr_fac).flatten

      # If we missed it, plow ahead.
      next unless w
      #puts "***Tiling #{plant_count}"
      tiler.tile(w)
      #puts "***done tiling #{plant_count}"

      @threads << ControllableThread.new { tend(w, plant_count, plant_time) }
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
    # Try to shrink twice.
    x1 = ImageUtils.shrink(x, 1)
    x2 = ImageUtils.shrink(x1, 1)

    point = ImageUtils.find_largest(x2, search_dir, REACH_RADIUS)
    point = ImageUtils.find_largest(x1, search_dir, REACH_RADIUS) unless point

    return nil, nil unless point
    
    spoint = x.to_screen(point)

    w = PinnableWindow.from_screen_click(spoint)
    w.pin if w

    return w, plant_time
  end
  
  def tend(w, plant_number, plant_time)
    # Times in sec (relative to plant time) at which to water.
    #
    # grow_times = [0, 15, 30, 45] # measured.
    water_times = [4, @vals['second'].to_i, @vals['third'].to_i]
    harvest_time = 46
    3.times do |index|
      target_secs = water_times[index]
      delta = (Time.new - plant_time)
      delay = target_secs - delta
      sleep_sec(delay)
      #puts "plant #{plant_number} watering #{index} at time #{(Time.new - plant_time)}"
      with_robot_lock do
        point = nil
        5.times do
          w.refresh
          point = w.dialogCoordsFor('Water')
          break if point
          sleep 0.02
        end
        @vegi_data[:water].times { w.dialogClick(point, nil, 0.0) } if point
      end
    end
    sleep_sec(harvest_time - (Time.new - plant_time))

    #puts "hargesting #{plant_number}"

    harvest_and_unpin(w)
  end

  # Harvest is weird.  takes a long time to happen.  Sometimes not at
  # all the first click. Keep trying until the menu becomes empty. 
  def harvest_and_unpin(w)
    done = false
    until done do
      with_robot_lock do
        w.refresh

        # Click on harvest if it's there, but we may not be done.
        w.click_on('Harvest')

        # If the menu is empty, then we're done.
        if w.read_text.size == 0
          w.unpin
          done = true
        end
      end
      sleep_sec(2)
    end
  end
end



Action.add_action(Onions.new)
