require 'action'

# Class for the PaintLab pinned window
class PaintLab 
  TOP_BUTTON = [17, 271]
  # Until mass prod.
  # TOP_BUTTON = [17, 255]
  INGREDIENTS = [
    :cabbage, :carrot, :clay, :dt, :ts, :el, :red_sand, :lead,
    :silver, :iron, :copper, :sulfur, :potash, :lime, :saltpeter,
  ]
  # Synonyms used by Practical Paint.
  INGREDIENTS2 = [
    'Cabbage', 'Carrot', 'Clay', 'DeadTongue',
    'ToadSkin', 'EarthLight', 'RedSand', 'Lead',
    'Silver', 'Iron', 'Copper', 'Sulfur', 'Potash', 'Lime', 'Saltpeter',
  ]
  CATALYSTS = [ :sulfur, :potash, :lime, :saltpeter ]
  CHEAP_ITEM = [:clay]
  
  def initialize()
    @buttons = {}
    @concentration = 0
    INGREDIENTS.size.times do |i|
      @buttons[INGREDIENTS[i]] = [TOP_BUTTON[0], TOP_BUTTON[1] + i * 18]
    end
    INGREDIENTS.each_index do |i|
      @buttons[INGREDIENTS2[i]] = @buttons[INGREDIENTS[i]]
    end
    
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
    rclick_at(*@buttons[i])
    sleep_sec(0.1)
    @concentration += 1 unless CATALYSTS.index(i)
  end

  def take
    recipe(CHEAP_ITEM) while @concentration < 10
    rclick_at(32, 92)
    @concentration = 0
  end

  RED_Y = 210
  GREEN_Y = 220
  BLUE_Y = 230
  def measure_colors
    sleep_sec(0.5)
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
    'AliceBlue : Carrot 1 Copper 1 Lead 1 Sulfur 1 Clay 7',
    'AntiqueWhite : Carrot 1 Iron 1 RedSand 1 Cabbage 1 Saltpeter 1 Clay 6',
    'Aqua : Silver 1 Copper 6 Lead 1 Clay 1 RedSand 1',
    'Aquamarine : Carrot 1 Silver 1 Copper 1 Lead 1 RedSand 1 Clay 5',
    'Azure : Carrot 2 Copper 2 Lead 1 Sulfur 1 Clay 5',
    'Beige : RedSand 1 Saltpeter 1 Iron 1 Cabbage 3 Silver 1 Clay 9',
    'Bisque : Carrot 1 Iron 1 RedSand 3 Cabbage 1 Saltpeter 1 Clay 7',
    'Black : Cabbage 1 Copper 1 Clay 7 RedSand 1',
    'BlanchedAlmond : Carrot 2 Iron 1 RedSand 2 Cabbage 1 Saltpeter 1 Clay 7',
    'Blue : Cabbage 6 Carrot 1 RedSand 1 DeadTongue 1 Copper 1 Silver 1',
    'BlueViolet : Carrot 1 RedSand 1 Lime 1 Saltpeter 1 Copper 1 Cabbage 7',
    'Brown : Cabbage 1 Clay 8 RedSand 1',
    'Burlywood : Iron 1 Cabbage 1 Saltpeter 1 Clay 8',
    'CadetBlue : Carrot 1 Iron 1 Silver 1 RedSand 1 Cabbage 1 Clay 5',
    'Carrot : Clay 9 Copper 1 Sulfur 1 Saltpeter 1',
    'Chocolate : Clay 8 Carrot 1 Copper 1',
    'Coral : Saltpeter 1 Clay 9 Copper 1 Sulfur 1',
    'CornflowerBlue : Carrot 1 Iron 1 Silver 1 RedSand 1 Cabbage 2 Clay 4',
    'Cornsilk : Carrot 9 Iron 1 RedSand 1 Cabbage 1 Saltpeter 1 Copper 1',
    'Crimson : Cabbage 1 Clay 7 Copper 1 RedSand 1 Sulfur 1',
    'DarkBlue : Cabbage 4 Carrot 1 Iron 1 Silver 1 RedSand 1 Clay 2',
    'DarkCyan : Clay 2 Carrot 1 Silver 1 RedSand 1 Cabbage 2 Copper 3',
    'DarkGoldenrod : Clay 5 RedSand 1 Cabbage 1 Carrot 3',
    'DarkGray : Clay 5 Carrot 1 Iron 1 RedSand 1 Cabbage 2',
    'DarkGreen : Cabbage 3 Copper 1 Clay 6 Saltpeter 1',
    'DarkKhaki : Clay 7 Iron 1 RedSand 1 Cabbage 1',
    'DarkMagenta : Cabbage 4 Clay 4 Carrot 1 RedSand 1',
    'DarkOliveGreen : Copper 1 Clay 9',
    'DarkOrange : Sulfur 1 Clay 10 Copper 1 Saltpeter 1',
    'DarkOrchid : Clay 2 Carrot 1 RedSand 1 Cabbage 6 Sulfur 1',
    'DarkRed : Cabbage 1 Clay 6 RedSand 2 Carrot 1',
    'DarkSalmon : Iron 1 Cabbage 1 RedSand 1 Saltpeter 1 Clay 7',
    'DarkSeaGreen : Lime 1 Carrot 1 Sulfur 1 Copper 1 Clay 8',
    'DarkSlateBlue : Cabbage 10',
    'DarkSlateGray : Cabbage 2 Copper 1 Clay 7',
    'DarkTurquoise : Carrot 1 Saltpeter 1 Silver 1 Copper 6 RedSand 1 Clay 1',
    'DarkViolet : Cabbage 8 Carrot 1 RedSand 1',
    'DeepPink : Cabbage 3 Clay 1 Copper 1 RedSand 1 Sulfur 1 Carrot 4',
    'DeepSkyBlue : Carrot 1 Saltpeter 1 Silver 1 Copper 7 RedSand 1 Cabbage 1',
    'DimGray : Clay 8 Carrot 1 RedSand 1',
    'DodgerBlue : Carrot 1 Saltpeter 1 Silver 1 Copper 4 RedSand 1 Cabbage 3',
    'Feldspar : Clay 8 Iron 1 Cabbage 1',
    'FireBrick : Cabbage 1 Clay 4 RedSand 1 Carrot 4',
    'FloralWhite : Carrot 5 Copper 1 Sulfur 1 Clay 3 Lead 1',
    'ForestGreen : Clay 8 Saltpeter 1 Silver 1 RedSand 1',
    'Gainsboro : Iron 1 RedSand 1 Cabbage 9 Saltpeter 1',
    'GhostWhite : Carrot 1 RedSand 1 Sulfur 1 Copper 1 Lead 1 Clay 6',
    'Gold : Clay 2 Iron 1 Lime 1 Carrot 7 Saltpeter 1',
    'Goldenrod : Clay 8 Carrot 1 Iron 1 Saltpeter 1',
    'Gray : Clay 7 Carrot 1 RedSand 1 Cabbage 1',
    'Green : Saltpeter 1 Silver 1 Copper 1 Clay 6 RedSand 2',
    'GreenYellow : Silver 1 Lime 1 Carrot 2 Lead 1 Sulfur 1 Clay 6',
    'Honeydew : Carrot 4 RedSand 1 Silver 1 Copper 1 Lead 1 Cabbage 2',
    'HotPink : Clay 6 Carrot 1 Copper 1 RedSand 1 Sulfur 1 Cabbage 1',
    'IndianRed : Clay 5 Carrot 4 RedSand 1',
    'Indigo : Cabbage 1 Carrot 1 Copper 1 Clay 6 RedSand 1',
    'Ivory : Carrot 6 RedSand 1 Saltpeter 1 Iron 1 Cabbage 1 Copper 2',
    'Khaki : Saltpeter 1 Clay 8 Iron 1 Cabbage 1',
    'Lavender : Carrot 1 Iron 1 RedSand 1 Cabbage 4 Saltpeter 1 Clay 3',
    'LavenderBlush : Carrot 1 RedSand 1 Saltpeter 1 Iron 1 Cabbage 4 Clay 3',
    'LawnGreen : Silver 1 Copper 1 DeadTongue 1 Lead 1 RedSand 1 Clay 7',
    'LemonChiffon : Copper 1 Lime 1 Carrot 1 Lead 1 Sulfur 1 Clay 7',
    'LightBlue : Carrot 1 Copper 2 Clay 5 Lead 1 RedSand 1',
    'LightCoral : Carrot 1 RedSand 1 Sulfur 1 Clay 7 Copper 1',
    'LightCyan : Carrot 1 Sulfur 1 Copper 2 Clay 6 Lead 1',
    'LightGoldenrodYellow : RedSand 1 Saltpeter 1 Iron 1 Cabbage 2 Silver 1 Clay 8',
    'LightGreen : Carrot 1 RedSand 1 Cabbage 1 Silver 1 Lead 1 Clay 5',
    'LightGrey : RedSand 1 Saltpeter 1 Copper 1 Iron 1 Cabbage 2 Clay 5',
    'LightPink : Saltpeter 1 Clay 4 Iron 1 Cabbage 5',
    'LightSalmon : Saltpeter 1 Iron 1 Cabbage 1 Sulfur 1 Clay 8',
    'LightSeaGreen : Copper 1 Silver 1 Clay 4 Lead 1 RedSand 1 Cabbage 2',
    'LightSkyBlue : Cabbage 5 Copper 2 Lead 1 Sulfur 1 Clay 2',
    'LightSlateBlue : Carrot 1 RedSand 1 Sulfur 1 Saltpeter 1 Copper 1 Cabbage 7',
    'LightSlateGray : Clay 1 Carrot 1 RedSand 1 Cabbage 7',
    'LightSteelBlue : Clay 5 Carrot 1 Lead 1 RedSand 1 Cabbage 3',
    'LightYellow : Copper 2 Lime 1 Carrot 1 Lead 1 Sulfur 1 Clay 6',
    'LimeGreen : Clay 7 Silver 1 Lead 1 RedSand 1 Cabbage 1',
    'Linen : Carrot 1 Sulfur 1 Clay 9 Copper 1 Lead 1',
    'Maroon  : Cabbage 1 Clay 8 RedSand 1 Sulfur 1',
    'MediumAquamarine : Clay 6 Carrot 1 Silver 1 Lead 1 RedSand 1',
    'MediumBlue  : Carrot 1 Sulfur 1 Iron 1 Silver 1 RedSand 1 Cabbage 8',
    'MediumOrchid : Clay 4 Carrot 1 Iron 1 Cabbage 3 RedSand 1',
    'MediumPurple : Carrot 1 Copper 1 Clay 5 RedSand 1 Sulfur 1 Cabbage 2',
    'MediumSeaGreen : Silver 1 Copper 1 RedSand 1 Cabbage 1 Sulfur 1 Clay 6',
    'MediumSlateBlue : Carrot 1 Iron 1 Cabbage 6 Silver 1 RedSand 1 Clay 2',
    'MediumSpringGreen : Silver 1 Copper 3 Clay 4 Lead 1 RedSand 1',
    'MediumTurquoise : Silver 1 Copper 1 Clay 2 Lead 1 RedSand 1 Cabbage 4',
    'MediumVioletRed : Cabbage 1 Clay 5 Carrot 3 RedSand 1',
    'MidnightBlue : Cabbage 3 Copper 1 Clay 5 RedSand 1',
    'MintCream : Carrot 3 Copper 3 Lead 1 Sulfur 1 Clay 2 RedSand 1',
    'MistyRose : Carrot 1 RedSand 1 Saltpeter 1 Iron 1 Cabbage 1 Clay 6',
    'Moccasin : Lime 1 Carrot 1 Saltpeter 1 Iron 1 Cabbage 2 Clay 6',
    'NavajoWhite : RedSand 1 Saltpeter 1 Iron 1 Cabbage 1 Sulfur 1 Clay 7',
    'Navy  : Lead 1 Carrot 1 Copper 1 Clay 3 RedSand 1 Cabbage 3',
    'OldLace : Carrot 6 Iron 1 RedSand 1 Cabbage 1 Saltpeter 1 Copper 1',
    'Olive : Clay 10 Saltpeter 1',
    'OliveDrab : Clay 8 RedSand 1 Cabbage 1',
    'Orange : Clay 3 RedSand 1 Carrot 5 Saltpeter 1 Iron 1',
    'OrangeRed : Cabbage 1 Clay 4 Copper 1 Sulfur 1 Saltpeter 1 RedSand 4',
    'Orchid : Clay 3 Carrot 1 Copper 1 RedSand 1 Sulfur 1 Cabbage 4',
    'PaleGoldenrod : Iron 1 Cabbage 1 Lime 1 Carrot 1 Saltpeter 1 Clay 7',
    'PaleGreen : Iron 1 Saltpeter 1 Silver 1 RedSand 1 Cabbage 1 Clay 6',
    'PaleTurquoise : Saltpeter 1 Iron 1 Silver 1 RedSand 1 Cabbage 3 Clay 5',
    'PaleVioletRed : Clay 6 Carrot 1 Iron 1 Cabbage 1 RedSand 1',
    'PapayaWhip : Carrot 3 RedSand 1 Saltpeter 1 Iron 1 Cabbage 1 Clay 8',
    'PeachPuff : RedSand 1 Saltpeter 1 Clay 1 Iron 1 Cabbage 7',
    'Peru : Iron 1 Saltpeter 1 Clay 9',
    'Pink : Carrot 1 Iron 1 RedSand 3 Cabbage 1 Saltpeter 1 Clay 4',
    'Plum : Carrot 1 Iron 1 Cabbage 1 RedSand 1 Saltpeter 1 Clay 6',
    'PowderBlue : Iron 1 Saltpeter 1 Silver 1 RedSand 1 Cabbage 2 Clay 5',
    'Purple  : Cabbage 1 Clay 7 Carrot 1 RedSand 1',
    'Red : Cabbage 1 Clay 1 Copper 1 RedSand 1 Carrot 9',
    'RosyBrown : Clay 6 Iron 1 Cabbage 3',
    'RoyalBlue : Carrot 1 Silver 1 RedSand 1 Saltpeter 1 Copper 1 Cabbage 6',
    'SaddleBrown : Clay 10',
    'Salmon : Clay 9 Copper 1 Sulfur 1',
    'SandyBrown : Clay 8 Iron 1 Cabbage 1 Saltpeter 1',
    'SeaGreen : Carrot 1 Copper 2 Clay 5 RedSand 1 Cabbage 1',
    'Seashell : Carrot 3 Sulfur 1 Clay 6 Copper 1 Lead 1',
    'Sienna : Cabbage 1 Clay 9',
    'Silver : Clay 2 Carrot 2 Iron 1 RedSand 1 Cabbage 4',
    'SkyBlue : Carrot 2 Silver 1 Lead 1 Clay 2 RedSand 1 Cabbage 3',
    'SlateBlue : Carrot 1 RedSand 1 Cabbage 8',
    'SlateGray : Clay 2 Carrot 1 RedSand 1 Cabbage 6',
    'Snow : Carrot 1 Copper 1 Lead 1 RedSand 1 Sulfur 1 Clay 6',
    'SpringGreen : Silver 1 Copper 4 Lead 1 RedSand 1 Cabbage 1 Clay 2',
    'SteelBlue  : Copper 1 Clay 1 Lime 1 Carrot 1 RedSand 1 Cabbage 6',
    'Tan : Clay 5 Carrot 2 Iron 1 RedSand 1 Cabbage 1',
    'Teal : Carrot 1 Silver 1 Copper 1 Clay 5 RedSand 1 Cabbage 1',
    'Thistle : Iron 1 RedSand 1 Cabbage 8 Saltpeter 1',
    'Tomato : Clay 8 RedSand 1 Carrot 1 Sulfur 1 Copper 1',
    'Turquoise : Silver 1 Copper 2 Clay 3 Lead 1 RedSand 1 Cabbage 2',
    'Violet : Carrot 1 Iron 1 Cabbage 2 RedSand 1 Saltpeter 1 Clay 5',
    'VioletRed : Clay 3 Iron 1 Cabbage 5 RedSand 1',
    'Wheat : Iron 1 RedSand 1 Cabbage 2 Sulfur 1 Saltpeter 1 Clay 6',
    'White : Carrot 3 Copper 1 Lead 1 RedSand 1 Sulfur 1 Clay 4',
    'WhiteSmoke : Carrot 1 Copper 1 Sulfur 1 Clay 7 Lead 1',
    'YellowGreen : Copper 1 RedSand 1 Cabbage 1 Sulfur 1 Saltpeter 1 Clay 7',
  ]
  def initialize
    super("PP paint", 'Misc')
    @recipes = {}
    @colors = []
    RECIPE_LINES.each do |l|
      color = l.split(':')[0].strip
      @recipes[color] = l
      @colors << color
    end
  end

  def persistence_name
    'Paint'
  end
  def get_vals(parent)
    comps = [
      {:type => :combo, :name => 'color', :label => 'Color: ', :vals => @colors},
      {:type => :number, :name => 'count', :label => 'How many batches? '},
    ]
    UserIO.prompt(parent, persistence_name, action_name, comps)
  end

  def setup(parent)
    @vals = get_vals(parent)
  end

  def act
    p = PaintLab.new

    recipe = @recipes[@vals['color']]
    count = @vals['count'].to_i
    ControllableThread.check_for_pause

    count.times do 
      color = p.pp_recipe(recipe)
      p.take
    end
  end
end
Action.add_action(PpPaint.new)

class MeasurePaint < Action

  def initialize
    super("Measure paint", 'Misc')

    @recipe = [

      [:cabbage, :dt],
      [:cabbage, :red_sand, :clay],
      [:cabbage, :silver],
      [:cabbage, :iron],
      [:cabbage, :copper],
      [:cabbage, :potash],
      [:cabbage, :lime],

      [:carrot, :dt],
      [:carrot, :ts, :cabbage],
      [:carrot, :red_sand],
      [:carrot, :lead],
      [:carrot, :iron],
      [:carrot, :potash, :red_sand],
      [:carrot, :lime],

      [:clay, :ts],
      [:clay, :dt],
      [:clay, :lead],
      [:clay, :silver, :cabbage],
      [:clay, :copper],
      [:clay, :sulfur],
      [:clay, :saltpeter, :cabbage],

      [:dt, :cabbage],
      [:dt, :carrot],
      [:dt, :ts],
      [:dt, :red_sand],
      [:dt, :lead],
      [:dt, :iron],
      [:dt, :copper],
      [:dt, :potash],
      [:dt, :lime],

      [:ts, :carrot, :cabbage],
      [:ts, :clay],
      [:ts, :dt],
      [:ts, :lead],
      [:ts, :copper, :red_sand],
      [:ts, :potash, :red_sand],
      [:ts, :lime, :red_sand],

      

      [:red_sand, :cabbage, :carrot],
      [:red_sand, :carrot, :copper],
      [:red_sand, :dt],
      [:red_sand, :silver],

      [:lead, :carrot],
      [:lead, :clay],
      [:lead, :dt],
      [:lead, :ts],
      [:lead, :silver],
      [:lead, :iron],
      [:lead, :copper],
      [:lead, :saltpeter],

      [:silver, :clay, :cabbage],
      [:silver, :red_sand],
      [:silver, :lead, :lead],
      [:silver, :iron, :copper],
      [:silver, :copper],
      [:silver, :saltpeter, :carrot],

      [:iron, :cabbage, :carrot],
      [:iron, :dt, :silver],
      [:iron, :lead],
      [:iron, :silver],
      [:iron, :sulfur],
      [:iron, :saltpeter],

      [:copper, :cabbage],
      [:copper, :clay],
      [:copper, :dt],
      [:copper, :ts],
      [:copper, :lead],
      [:copper, :silver],
      [:copper, :sulfur],
      [:copper, :saltpeter],

      [:sulfur, :clay],
      [:sulfur, :iron],
      [:sulfur, :copper],
      [:sulfur, :potash, :lead],

      [:potash, :cabbage],
      [:potash, :carrot, :cabbage],
      [:potash, :dt],
      [:potash, :ts],
      [:potash, :sulfur, :red_sand],

      [:lime, :carrot],
      [:lime, :clay],
      [:lime, :dt],
      [:lime, :ts],

      [:saltpeter, :clay, :cabbage],
      [:saltpeter, :red_sand],
      [:saltpeter, :lead],
      [:saltpeter, :silver, :carrot],
      [:saltpeter, :iron],
      [:saltpeter, :copper],
    ]
    @recipe = [
      [:silver, :lead,],
      [:silver, :lead, :lead],
      [:silver, :lead, :lead, :lead],
      [:silver, :lead, :lead, :lead, :lead],
    ]
  end

  def act
    check_ingredients(@recipe)
    p = PaintLab.new
    @recipe.each do |rec|
      p.recipe(rec)
      r, g, b =  p.measure_colors
      show(rec, r, g, b)
      p.take
    end
  end

  def check_ingredients(r)
    r.each {|rr|
      rr.each {|i|
	raise("Didn't find #{i}") unless PaintLab::INGREDIENTS.index(i)
      }
    }
  end

  def show(recipe, r, g, b)
    File.open('m.txt', 'a+') {|file|
      recipe.each {|rcp| file.print(rcp.to_s + ", ") }
      file.print ", " if recipe.size < 3
      file.puts(" #{r}, #{g}, #{b},")
    }
  end

end
