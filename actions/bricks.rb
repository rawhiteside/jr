require 'action'
require 'walker'
require 'user-io'

class Bricks < GridAction
  def initialize
    super('Bricks', 'Buildings')
  end

  def get_gadgets
    add = [ {:type => :text, :label => 'String to send', :name => 'string'}]
    super + add
  end

  def act_at(p)
    mm(p['x'],p['y'])
    sleep_sec 0.2
    send_string(@user_vals['string'], 0.3)
  end
end
Action.add_action(Bricks.new)

class FlimsyBricks < GridAction

  def initialize
    super('Flimsy Bricks', 'Buildings')
    @recipes = build_recipes
    @project_menu = nil
  end

  def get_gadgets
    add = [ {:type => :label, :label => 'Cols and Rosw must be 5!!'}, ]
    add + super + [ {:type => :text, :label => 'String to send', :name => 'string'}]
  end

  # Is the pixel a brickrack color?
  def brick_rack_brown?(x, y)
    color = get_color(x, y)
    r, g, b = color.red, color.green, color.blue
    r_rng = 1..200
    g_rng = 1..150
    b_rng = 1..110

    rv = r_rng.include?(r) && g_rng.include?(g) && b_rng.include?(b) &&
      (r - g) > 5 && (r - b) > 5
    rv
  end

  def check_build(p)
    mm(p['x'], p['y'])
    return if brick_rack_brown?(p['x'], p['y'])
    @project_menu.click_on('Build a Flimsy')
    key = [p['ix'],p['iy']]
    recipe = @recipes[key]
    BuildMenu.new.build(recipe)
    sleep_sec(1)
  end

  def act_at(pt)
    @project_menu = PinnableWindow.from_point(Point.new(50, 60)) unless @project_menu
    
    raise Exception.new('Expected projects menu pinned UL') unless @project_menu

    skip_these = [ [2, 2], ]
    ij = [pt['ix'], pt['iy']]
    return if skip_these.index(ij)

    check_build(pt)


    mm(pt['x'], pt['y'])
    sleep_sec 0.3
    send_string(@user_vals['string'], 0.3)
    sleep_sec 0.3
  end

  def build_recipes
    h  = {}
    # The ones around me.
    # keys are [ix, iy]
    h[[1, 1]] = [:nw, :nw]
    h[[2, 1]] = [:n, :n]
    h[[3, 1]] = [:ne, :ne]
    h[[1, 2]] = [:w, :w]
    h[[3, 2]] = [:e, :e]
    h[[1, 3]] = [:sw, :sw]
    h[[2, 3]] = [:s, :s]
    h[[3, 3]] = [:se, :se]

    h[[0, 0]] = [:nw, :nw, :nw, :nw, ]
    h[[0, 1]] = [:w, :w] + h[[1, 1]]
    h[[0, 2]] = [:w, :w] + h[[1, 2]]
    h[[0, 3]] = [:w, :w] + h[[1, 3]]

    h[[4, 0]] = [:ne, :ne, :ne, :ne]
    h[[4, 1]] = [:e, :e] + h[[3, 1]]
    h[[4, 2]] = [:e, :e] + h[[3, 2]]
    h[[4, 3]] = [:e, :e] + h[[3, 3]]
    h[[4, 4]] = [:se, :se, :se, :se, ]

    h[[1, 0]] = [:n, :n] + h[[1, 1]]
    h[[2, 0]] = [:n, :n] + h[[2, 1]]
    h[[3, 0]] = [:n, :n] + h[[3, 1]]

    h[[0, 4]] = [:sw, :sw, :sw, :sw, ]
    h[[1, 4]] = [:s, :s] + h[[1, 3]]
    h[[2, 4]] = [:s, :s] + h[[2, 3]]
    h[[3, 4]] = [:s, :s] + h[[3, 3]]
    h
  end

end
  
Action.add_action(FlimsyBricks.new)
