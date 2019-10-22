require 'icons'
require 'action.rb'
require 'window'

class Vegetables < Action
  def initialize(name = "Grow vegetables", category = 'Plants')
    super(name, category)
    @threads = []
  end

  VEGETABLE_DATA = {
    "Cucumbers/Wadjet's Garden/(2) grass" => {
      :water => 2,
      :min_width => 240,
    },
    "Peppers/Isis/(3/4) dirt/sand" => {
      :water => 3,
      :tendings => 4,
      :min_width => 240,
    },
    "Peppers/Ptah's Breed/(2) dirt" => {
      :water => 2,
      :min_width => 240,
    },
    "Peppers/Ra's Fire/(1) dirt" => {
      :water => 1,
      :min_width => 240,
    },

    "Cabbage/Mut's Fruition/(1)" => {
      :water => 1,
      :min_width => 241,
    },
    "Cabbage/Bastet's Yielding/(2)" => {
      :water => 2,
      :min_width => 241,
    },
    

    "Carrots/Osiris' Orange/(1)" => {
      :water => 1,
      :min_width => 235,
    },
    "Carrots/Green Leaf/(2)" => {
      :water => 2,
      :min_width => 235,
    },


    "Garlic/Apep's Crop/(2)" => {
      :water => 2,
      :min_width => 209,
    },
    "Garlic/Heket's Reaping/(1)" => {
      :water => 1,
      :min_width => 209,
    },


    "Leeks/Horus' Grain/(3 waters!)" => {
      :water => 3,
      :min_width => 211,
    },
    "Leeks/Hapi's Harvest/(1)" => {
      :water => 1,
      :min_width => 211,
    },


    "Onions/Amun's Bounty/(1)" => {
      :water => 1,
      :min_width => 228,
    },
    'Onions/Tears of Sinai/(2)' => {
      :water => 2,
      :min_width => 228,
    },

    'Watermelons/Geb\'s Produce/(1)' => {
      :water => 1,
      :min_width => 272,
    },
  }

  # Size of a side of the square we look at to detect plants. Square
  # will be centered on your head.
  SQUARE_SIZE = 300

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
      {:type => :number, :label => 'Fourth water (~30-45).', :name => 'fourth'},
    ]
    @vals =  UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def stop
    @threads.each {|t| t.kill} if @threads
    super
  end

  def act
    walker = Walker.new
    @vegi_choice =  @vals['veggie']
    @vegi_name = @vals['veggie'].split('/')[1].strip
    puts @vegi_name
    @vegi_data = VEGETABLE_DATA[@vals['veggie']]
    @repeat = @vals['repeat'].to_i
    @grow_location = WorldLocUtils.parse_world_location(@vals['grow'])
    @water_location = WorldLocUtils.parse_world_location(@vals['water'])
    @head_rect = Rectangle.new(@vals['head.x'].to_i - SQUARE_SIZE/2,
                               @vals['head.y'].to_i - SQUARE_SIZE/2, 
                               SQUARE_SIZE, SQUARE_SIZE)
    @plant_win = PinnableWindow.from_point(Point.new(@vals['plant.x'].to_i, @vals['plant.y'].to_i))
    if @plant_win.nil?
      puts "Didn't find plant menu."
      return
    end

    beds = @vals['beds'].to_i

    loop do
      walker.walk_to(@grow_location)
      walker.up
      walker.down
      sleep_sec(1)
      repeat.times do
        @plant_win.refresh
        one_pass(beds)
      end
      walker.walk_to(@water_location)
      Icons.refill
    end

  end

  def one_pass(max_plants)

    xhead = @vals['head.x'].to_i
    yhead = @vals['head.y'].to_i

    # Needs to be down below the build menu.
    tiler = Tiler.new(0, 190, 0.0)
    tiler.y_offset = 20
    tiler.min_width = @vegi_data[:min_width]
    plant_count = 0
    
    build_recipe_left = [ [:nw], [:w], [:w, :w], [:nw, :w], [:sw], [:sw, :w], ]
    build_recipe_right = [ [:ne], [:e], [:e, :e], [:ne, :e], [:se], [:se, :e], ]
    
    plant_side(max_plants/2, tiler, build_recipe_left, 'left')
    plant_side(max_plants - (max_plants/2), tiler, build_recipe_right, 'right')

    @threads.each {|t| t.join}
  end

  def plant_side(num, tiler, build_recipe, left_right)
      num.times do |index|
        w, plant_time = plant_and_pin(build_recipe[index], left_right)

        # If we missed it, plow ahead.
        next unless w

        tiler.tile(w)
        @threads << ControllableThread.new { tend(w, plant_time) }
        sleep 0.001
      end
  end

  def plant_and_pin(build_recipe, search_dir)

    w = nil
    plant_time = nil
    before = nil
    
    with_robot_lock do 
      before = PixelBlock.new(@head_rect)
      @plant_win.refresh
      @plant_win.click_on(@vegi_name)
      builder = BuildMenu.new
      builder.build(build_recipe)
      plant_time = Time.new
    end


    # Sometimes the plant is slow to render
    point = x = nil
    3.times do

      after = PixelBlock.new(@head_rect)

      x = ImageUtils.brightness(ImageUtils.xor(before, after))
      # Shrink until there's no largest.

      point = nil
      point_count = 0
      while true
        xnew = ImageUtils.shrink(x, 1)
        point_new = ImageUtils.find_largest(xnew, search_dir, REACH_RADIUS)
        break if point_new.nil?
        x = xnew
        point_count += 1
        point = point_new
      end
      break unless point.nil?
      sleep 1
    end

    return nil, nil unless point
    
    spoint = x.to_screen(point)

    w = PinnableWindow.from_screen_click(spoint)
    w.pin if w

    return w, plant_time
  end
  
  def tend(w, plant_time)
    # Times in sec (relative to plant time) at which to water.
    #
    # grow_times = [0, 15, 30, 45] # measured.
    water_times = [4, @vals['second'].to_i, @vals['third'].to_i]
    tmp = @vegi_data[:tendings]
    if tmp.nil?
      tend_count = 3
    else
      tend_count = tmp
    end
    water_times << @vals['fourth'].to_i if tend_count == 4
    
    harvest_time = water_times.last + 8
    tend_count.times do |index|
      target_secs = water_times[index]
      delta = (Time.new - plant_time)
      delay = target_secs - delta
      sleep_sec(delay)
      with_robot_lock do
        # At first, maybe have to wait for the menu to initialize itself.
        if index == 0
          until w.dialog_coords_for('Water')
            sleep_sec 0.5 
            w.refresh
          end
        end
        @vegi_data[:water].times { w.click_on('Water') }
      end
    end
    sleep_sec(harvest_time - (Time.new - plant_time))


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



Action.add_action(Vegetables.new)
