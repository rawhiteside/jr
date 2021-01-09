require 'action'

class Treatment < Action
  WOOD = 'Wood'
  METAL = 'Metal'
  TANK_INFO = {
    'Wood' => {'prefix' => 'Treat/Treat with '},
    'Metal' => {'prefix' => 'Dissolve/Dissolve '},
  }
  DONE_TEXT = 'Processing Complete'

  def initialize
    super('Treat metal/wood', 'Buildings')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :name => 'win', :label => 'Drag to pinned tank window'},
      {:type => :combo, :name => 'tank', :label => 'Type of treatment',
       :vals => TANK_INFO.keys,},
      {:type => :number, :name => 'count', :label => 'Number of batches'},
      {:type => :text, :label => 'Metal name (for metal only)', :name => 'metal-type'},
      {:type => :label, :label => 'Recipe is a list of time, ingredient lines.  As in:'},
      {:type => :label, :label => '  20, Lime'},
      {:type => :label, :label => '  75, Petroleum'},
      {:type => :big_text, :label => 'Recipe', :name => 'recipe'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act

    win = PinnableWindow.from_point(point_from_hash(@vals, 'win'))
    @tank_type = @vals['tank']
    @tank_data = TANK_INFO[@tank_type]
    repeat = @vals['count'].strip.to_i
    repeat.times { treat_one_batch(win) }
  end

  def treat_one_batch(win)
    tank_type = @vals['tank']
    wait_for_treatment_done(win)
    take_stuff(win)
    sleep 2
    load_stuff(win)
    sleep 2
    recipe = @vals['recipe'].split("\n")
    recipe.each do |line|
      next if line.strip == ''
      parts = line.split ','
      seconds = parts[0].strip
      ingredient = parts[1].strip
      add_ingredient(win, seconds, ingredient)
      sleep 1
      wait_for_treatment_done(win)
    end
  end

  def treating_metal?
    @tank_type == METAL
  end

  def take_stuff(win)
    win.click_on('Take')
  end

  def add_ingredient(win, seconds, ingredient)
    win.refresh
    prefix = @tank_data['prefix']
    if win.click_on(prefix + ingredient)
      HowMuch.amount(seconds)
    else
      puts "Failed to click on \"#{prefix + ingredient}\""
    end
  end

  def wait_for_treatment_done(win)
    loop do
      win.refresh
      text = win.read_text
      break if text.include?(DONE_TEXT)
      sleep 3
    end
  end

  def load_stuff(win)
    if treating_metal?
      metal = @vals['metal-type']
      HowMuch.max if win.click_on("Load/#{metal}")
    else
      HowMuch.max if win.click_on('Load Boards')
    end
  end

end

Action.add_action(Treatment.new)
