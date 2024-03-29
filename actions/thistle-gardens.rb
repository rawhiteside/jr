class ThistleGardens < GridAction

  REFRESH_DELAY = 0.1
  def initialize(name = 'Thistle Gardens', category = 'Buildings')
    super(name, category)
  end

  def get_recipe
    rtext = @vals['recipe']
    recipe = []
    rtext.split("\n").each do |line|
      recipe << line unless line.strip == ''
    end
    return recipe
  end

  VAL_FOR_SHADE = {
    'Open' => 99,
    'Shading' => 33,
    'It is night' => 0,
  }

  def get_gadgets
    add = [
      
      {:type => :big_text, :label => 'Automato Thistle mode recipe', :name => 'recipe', :cols => 30, :rows => 10},
      {:type => :combo, :label => 'Sun shade is:', :name => 'shade',
            :vals => VAL_FOR_SHADE.keys}]
    super + add
  end
  
  def act
    @vals = @user_vals
    recipe = get_recipe

    repeat = @vals['repeat'].to_i
    @shade_state = VAL_FOR_SHADE[@vals['shade']]

    if (recipe.size != 41)
      puts "Bad recipe text.  #{recipe.size} instead of 40"
      return
    end

    windows = cascade_windows
    # The bold text needs bigger space threshold
    windows.each {|w| w.set_space_pixel_count(6)}

    # Make an initial pass through, harvesting if there's anything to harvest.
    harvest_batch(windows)
    
    repeat.times do
      make_batch(windows, recipe)
      harvest_batch(windows)
      fill_jugs
    end

    unpin_windows(windows)
  end

  def unpin_windows(windows)
    windows.each do |win|
      win.refresh
      sleep REFRESH_DELAY
      win.unpin
    end
  end

  def make_batch(windows, recipe)
    start_batch windows
    
    recipe.each_index do |tick|
      tick_ingredients = recipe[tick].split(',').collect{|v| v.strip.to_i}
      if (has_ingredients?(tick_ingredients))
        act_at_tick(windows, tick, tick_ingredients)
      end
    end
    windows.each {|w| wait_for_tick(40, w)}
  end

  def has_ingredients?(ingredients)
    ingredients.each do |ingredient|
      # Sun is either 33 or 99 or 0
      if ingredient > 30
        return true if ingredient != @shade_state
      else
        return true if ingredient > 0
      end
    end
    return false
  end
  
  BUTTONS = ['Nit', 'Pot', 'H20', 'Oxy', 'Sun']
  def act_at_tick(windows, tick, tick_ingredients)
    windows.each do |win|
      win.refresh
      sleep REFRESH_DELAY
      wait_for_tick(tick, win)
      tick_ingredients.each_index do |igred|
        ingredient = tick_ingredients[igred]
        # TODO:  Sun. 
        if ingredient > 0
          if BUTTONS[igred] == 'Sun'
            if @shade_state != ingredient
              win.click_word('Sun')
            end
          else
            ingredient.times {win.click_word(BUTTONS[igred])}
          end
        end
      end
    end
    @shade_state = tick_ingredients[4]
  end

  def wait_for_tick(tick, win)
    loop do
      win.refresh
      last_line = win.read_text.split("\n").pop
      this_tick = last_line.strip.split(' ')[0].to_i
      return if this_tick >= tick
      sleep 1
    end
  end

  def cascade_windows
    cascader = Cascader.new
    windows = []
    
    # Pin the windows and stage.
    GridHelper.new(@vals, 'g').each_point do |p|
      pt = Point.new(p['x'], p['y'])
      w = PinnableWindow.from_screen_click(pt)
      w.static_size = true
      w.pin
      cascader.stage(w)
      windows << w
    end
    cascader.cascade_from_stage
    return windows
  end    

  def start_batch(windows)
    windows.each do |win| 
      win.refresh
      win.click_on 'Crop: Plant'

      # I've seen the "Plant" fail.
      win.refresh
      while win.read_text.include?('Plant')
        sleep REFRESH_DELAY
        win.flush_text_reader
        puts "clicking again"
        win.click_on 'Crop: Plant'
      end
    end
  end

  def harvest_batch(windows)
    windows.each do |win| 
      win.refresh 
      sleep REFRESH_DELAY
      win.click_on 'Crop: Harvest'
    end
  end
end
Action.add_action(ThistleGardens.new)



class ThistleWarehouse < Action
  def initialize(name = 'Thistle WH', category = 'Buildings')
    super(name, category)
  end
    
  def setup(parent)
    gadgets = [
      {:type => :text, :cols =>10, :label => 'Requirements:', :name => 'requirements'},
      {:type => :big_text, :cols => 30, :rows => 10, :label => 'Paste warehouse here.', :name => 'warehouse'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    lines_matching = []
    warehouse_text = @vals['warehouse']
    req_text = @vals['requirements'].upcase
    r1 = req_text[0,2]
    r2 = req_text[2,2]
    r3 = req_text[4,2]
    r4 = req_text[6,2]
    warehouse_text.split("\n").each do |line|
      next unless line.include?('Thistle:')
      next unless line.include?(r1)
      next unless line.include?(r2)
      next unless line.include?(r3)
      next unless line.include?(r4)
      lines_matching << line
    end
    msg = 'No matches found.'
    if lines_matching.size > 0
      msg = lines_matching.join("\n")
    end
    UserIO.info(msg)
  end
  
end

Action.add_action(ThistleWarehouse.new)
