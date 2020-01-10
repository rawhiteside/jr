require 'action'

# Class for the PaintLab pinned window
class PaintLab < AWindow
  TOP_BUTTON = [16, 261]  # Relative to window. 
  INGREDIENTS = [
    :cabbage, :carrot, :clay, :dt, :ts, :fb, :red_sand, :lead,
    :silver, :iron, :copper, :sulfur, :potash, :lime, :saltpeter,
  ]
  # Synonyms used by Practical Paint.
  INGREDIENTS2 = [
    'Cabbage', 'Carrot', 'Clay', 'DeadTongue',
    'ToadSkin', 'FalconBait', 'RedSand', 'Lead',
    'Silver', 'Iron', 'Copper', 'Sulfur', 'Potash', 'Lime', 'Saltpeter',
  ]
  CATALYSTS = [ :sulfur, :potash, :lime, :saltpeter ]
  CHEAP_ITEM = [:clay]
  
  def initialize(pinnable)
    super pinnable.rect
    @buttons = {}
    @concentration = 0
    INGREDIENTS.size.times do |i|
      @buttons[INGREDIENTS[i]] = [TOP_BUTTON[0], TOP_BUTTON[1] + i * 18]
    end
    INGREDIENTS.each_index do |i|
      @buttons[INGREDIENTS2[i]] = @buttons[INGREDIENTS[i]]
    end
    p @buttons
  end

  # Format is:
  # AliceBlue : Carrot 1 Copper 1 Lead 1 Sulfur 1 Clay 7
  #
  def pp_recipe(str)
    s = str.split(':')
    color = s[0].strip
    r = s[1].strip
    recipe = r.split(' ')
    while ingredient = recipe.shift
      count = recipe.shift.to_i
      count.times {|i|
	add_ingredient(ingredient)
      }
    end
    return color
  end

  def recipe(list)
    list.each {|i| add_ingredient(i) }
  end

  def add_ingredient(i)
    sleep 0.1
    dialog_click(Point.new(*@buttons[i]))
    sleep 0.1
    @concentration += 1 unless CATALYSTS.index(i)
  end

  def take
    recipe(CHEAP_ITEM) while @concentration < 10
    click_on('Take')
    @concentration = 0
  end

  RED_Y = 210
  GREEN_Y = 220
  BLUE_Y = 230
  def measure_colors
    sleep(0.5)
    red = count_matching(RED_Y) { |color| color.green < 10 }
    green = count_matching(GREEN_Y) { |color| color.blue < 10 }
    blue = count_matching(BLUE_Y) { |color| color.red < 10 }
    return red, green, blue
  end

  def count_matching(y)
    x = 10
    x += 1 while yield(get_color(x, y))
    if x <= 10
      x = "Low"
    elsif x >= 269
      x = "High"
    else
      x = x - 1
    end
    return x
  end
end

class PpPaint < Action
  RECIPE_LINES = [
    "Aquamarine: Iron 1 Copper 9",
  ]
  def initialize
    super("Paint", 'Misc')
    @recipes = {}
    @colors = []
    RECIPE_LINES.each do |l|
      color = l.split(':')[0].strip
      @recipes[color] = l
      @colors << color
    end
  end

  def get_vals(parent)
    comps = [
      {:type => :point, :label => "Drag to the paint window", :name => 'win'},
      {:type => :combo, :name => 'color', :label => 'Color: ', :vals => @colors},
      {:type => :number, :name => 'count', :label => 'How many batches? '},
    ]
    UserIO.prompt(parent, persistence_name, action_name, comps)
  end

  def setup(parent)
    @vals = get_vals(parent)
  end

  def act
    win = PinnableWindow.from_point(@vals['win.x'].to_i, @vals['win.y'].to_i)
    paint_win = PaintLab.new(win)

    recipe = @recipes[@vals['color']]
    count = @vals['count'].to_i
    check_for_pause

    count.times do 
      color = paint_win.pp_recipe(recipe)
      paint_win.take
    end
  end
end
Action.add_action(PpPaint.new)

