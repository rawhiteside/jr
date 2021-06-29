require 'icons'
require 'action.rb'
require 'window'

class Vegetables < Action
  def initialize(name = "Grow vegetables", category = 'Plants')
    super(name, category)
  end

  VEGETABLE_DATA = {
    "Eggplant/Qetesh's Soil/(2) sand" => {
      :water => 2,
      :min_width => 240,
    },
    "Eggplant/Stranger's Solana/(2) sand" => {
      :water => 2,
      :min_width => 240,
    },
    "Eggplant/Isis' Bounty/(4) sand" => {
      :water => 3,
      :min_width => 240,
    },
    "Eggplant/Isis Seed/(1) sand" => {
      :water => 1,
      :min_width => 240,
    },
    "Cucumbers/Isis' Bounty/(4) grass, dirt, sand" => {
      :water => 3,
      :tendings => 4,
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


    "Leeks/Horus' Grain/(2) sand" => {
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
    "Onions/Tears of Sinai/(2)" => {
      :water => 2,
      :min_width => 228,
    },

    "Watermelons/Geb's Produce/(1) grass" => {
      :water => 1,
      :min_width => 272,
    },
    "Watermelons/Isis' Bounty/(4) grass, sand" => {
      :water => 3,
      :tendings => 4,
      :min_width => 272,
    },
    "Watermelons/Set's Vintage/(2) grass" => {
      :water => 2,
      :min_width => 272,
    },
  }

  # Size of a side of the square we look at to detect plants. Square
  # will be centered on your head.
  SQUARE_SIZE = 500

  # The distance out that Jaby's arm reaches from the center of her
  # head.  Actually, picking up is larger.  Using this value for now. 
  REACH_RADIUS = 40

  def setup(parent)
    gadgets = [
      {:type => :combo, :label => 'What to grow?:', :name => 'veggie', 
       :vals => VEGETABLE_DATA.keys.sort},
      {:type => :world_loc, :label => 'Growing spot', :name => 'grow'},
      {:type => :world_loc, :label => 'Location of water', :name => 'water'},
      {:type => :point, :label => 'Drag onto plant button', :name => 'plant'},
      {:type => :number, :label => 'Rounds until water needed', :name => 'repeat'},
      {:type => :number, :label => 'Number of beds.', :name => 'beds'},
      {:type => :number, :label => 'Second water (~15-30).', :name => 'second'},
      {:type => :number, :label => 'Third water (~30-45).', :name => 'third'},
      {:type => :number, :label => 'Fourth water (~30-45).', :name => 'fourth'},
      {:type => :checkbox, :label => 'Overhead camera.', :name => 'f8-cam'},
      
    ]
    @vals =  UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    walker = Walker.new
    @vegi_choice =  @vals['veggie']
    @vegi_name = @vals['veggie'].split('/')[1].strip

    @is_f8 = (@vals['f8-cam'] == 'true')

    @vegi_data = VEGETABLE_DATA[@vals['veggie']]
    @repeat = @vals['repeat'].to_i
    @grow_location = WorldLocUtils.parse_world_location(@vals['grow'])
    @water_location = WorldLocUtils.parse_world_location(@vals['water'])
    dim = screen_size
    @head_rect = Rectangle.new(dim.width/2 - SQUARE_SIZE/2,
                               dim.height/2 - SQUARE_SIZE/2, 
                               SQUARE_SIZE, SQUARE_SIZE)
    @plant_win = PinnableWindow.from_point(Point.new(@vals['plant.x'].to_i, @vals['plant.y'].to_i))
    if @plant_win.nil?
      UserIO.error "Didn't find plant menu."
      return
    end

    beds = @vals['beds'].to_i

    did_walk = true
    loop do
      walker.walk_to(@grow_location)
      if did_walk && @is_f8
        walker.up
        walker.down
      end
      sleep(1)
      repeat.times do
        @plant_win.refresh
        one_pass(beds)
      end
      walker.walk_to(@water_location)
      Icons.refill
      did_walk = @water_location != @grow_location
    end

  end

  def one_pass(max_plants)

    # Needs to be down below the build menu.  Negative overlap, as the
    # windows get larger at harvest time.
    tiler = Tiler.new(0, 190, -0.15)
    tiler.y_offset = 20
    tiler.min_width = @vegi_data[:min_width]
    plant_count = 0
    
    build_recipe_left =  [ [:nw], [:w], [:w, :w], [:sw],  ]
    build_recipe_right = [ [:ne], [:e], [:e, :e], [:se], ]
    
    plant_side(max_plants/2, tiler, build_recipe_left, 'left')
    plant_side(max_plants - (max_plants/2), tiler, build_recipe_right, 'right')

    wait_for_worker_threads
  end

  def plant_side(num, tiler, build_recipe, left_right)
      num.times do |index|
        w, plant_time = plant_and_pin(build_recipe[index], left_right)

        # If we missed it, plow ahead.
        next unless w

        tiler.tile(w)
        start_worker_thread { tend(w, plant_time) }
        sleep 0.001
      end
  end

  def plant_and_pin(build_recipe, search_dir)

    w = nil
    plant_time = nil
    before = nil
    
    with_robot_lock do 
      before = PixelBlock.new(@head_rect)
      @plant_win.click_on('Plant')
      builder = BuildMenu.new
      builder.build(build_recipe)
      plant_time = Time.new
    end

    sleep 0.6
    after = PixelBlock.new(@head_rect)

    point = find_click_point(before, after, search_dir)

    return nil, nil unless point
    
    spoint = before.to_screen(point)

    w = PinnableWindow.from_screen_click(spoint)
    w.pin if w
    UserIO.show_image(ImageUtils.xor(before, after)) if w.nil? 
    UserIO.show_image(make_search_image(before, after)) if w.nil?

    return w, plant_time
  end

  def find_click_point(before, after, search_dir)
    return find_click_point_f8(before, after, search_dir) if @is_f8
    return find_click_point_f7(before, after, search_dir)
  end

  def make_search_image(before, after)
    xor = ImageUtils.brightness(ImageUtils.xor(before, after))
    ImageUtils.applyThreshold(xor, 15)

    # Shrink thrice
    xor = ImageUtils.shrink(ImageUtils.shrink(ImageUtils.shrink(xor)));
    return xor
  end
  # When looking from face-on (onions)
  def find_click_point_f7(before, after, search_dir)
    xor = make_search_image(before, after)

    # Clobber the center column (where Jaby is standing)
    xstart = xor.width / 2 - REACH_RADIUS
    xor.rect.height.times do |y|
      xstart.upto(xstart + 2 * REACH_RADIUS) do |x|
        xor.set_pixel(x, y, 0)
      end
    end

    # Now, search up from the bottom and find a non-zero pixel.
    (xor.rect.height - 1).downto(0) do |y|
      xor.rect.width.times do |x|
        return Point.new(x, y) if xor.get_pixel(x, y) != 0
      end
    end


    return nil
  end    
  
  # When looking from above. 
  def find_click_point_f8(before, after, search_dir)

    x = ImageUtils.brightness(ImageUtils.xor(before, after))

    # Shrink until there's no largest.
    point_count = 0
    while true
      # Remove all edge pixels. 
      xnew = ImageUtils.shrink(x)
      # XXX This find_largest is silly, since this is an xor image.  What was I thinking?  
      point_new = ImageUtils.find_largest(xnew, search_dir, REACH_RADIUS)
      break if point_new.nil?
      x = xnew
      point_count += 1
      point = point_new
    end
    return point
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
      sleep(delay)
      # At first, maybe have to wait for the menu to initialize itself.
      if index == 0
        until w.coords_for_line('Water')
          sleep 0.5 
          w.refresh
        end
      end
      w.refresh
      @vegi_data[:water].times do
        w.click_on('Water')
      end
    end
    sleep(harvest_time - (Time.new - plant_time))


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
      sleep(2)
    end
  end
end



Action.add_action(Vegetables.new)
