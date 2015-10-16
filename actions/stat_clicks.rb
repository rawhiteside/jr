require 'action'

class TimerAction < Action
  
end


class DigDirt < Action
  def initialize
    super('Dig dirt', 'Gather')
  end

  def act
    xy = [92, 65]
    stat = 'End'
    loop do
      stat_wait('End')
      rclick_at(xy[0], xy[1])
      sleep_sec 1
    end
  end
end
Action.add_action(DigDirt.new)

class DigStones < Action
  def initialize
    super('Dig Stones', 'Gather')
  end

  def setup(parent)
    comps = [
      {:type => :point, :name => 'p', :label => 'Drag to pinned Dig'},
    ]
    @vals = UserIO.prompt(parent, nil, @name, comps)
  end

  def act
    w = PinnableWindow.from_point(point_from_hash(@vals, 'p'))
    return unless w

    xy = [225, 65]
    loop do
      stat_wait('End')
      w.refresh
      w.click_on('Dig')
      sleep_sec(5)  # MAGIC.  Dig happens server side and lag.
    end
  end
end
Action.add_action(DigStones.new)

class EnduranceClick < Action
  def initialize
    super('Endurance click', 'Misc')
  end

  def setup(parent)
    comps = [
      {:type => :point, :name => 'p', :label => 'Drag to click location'},
    ]
    @vals = UserIO.prompt(parent, nil, @name, comps)
  end

  def act
    xy = [@vals['p.x'].to_i, @vals['p.y'].to_i]
    loop do
      stat_wait('End')
      rclick_at(*xy)
      sleep_sec 1
    end
  end
end
Action.add_action(EnduranceClick.new)

class Stir < Action
  def initialize
    super('Stir', 'Misc')
  end

  def setup(parent)
    comps = [
      {:type => :point, :name => 'p', :label => 'Drag to Pinned Clinker'},
    ]
    @vals = UserIO.prompt(parent, nil, @name, comps)
  end

  def act
    pt = point_from_hash(@vals, 'p')
    win = PinnableWindow.from_point(pt)
    loop do
      stat_wait('End')
      stat_wait('Str')
      win.refresh
      unless win.click_on('Stir the')
	sleep_sec 1
      end
      sleep_sec 1
    end
  end
end
Action.add_action(Stir.new)

class StrengthClick < Action
  def initialize
    super('Strength click', 'Misc')
  end

  def setup(parent)
    comps = [
      {:type => :point, :name => 'p', :label => 'Drag to click location'},
    ]
    @vals = UserIO.prompt(parent, nil, @name, comps)
  end

  def act
    xy = [@vals['p.x'].to_i, @vals['p.y'].to_i]
    loop do
      stat_wait('Str')
      rclick_at(*xy)
      sleep_sec 1
    end
  end
end
Action.add_action(StrengthClick.new)

class Eat < Action
  def initialize
    super('Eat', 'Misc')
  end

  # Eat iff:
  # - Looking at skills window
  # - Can see all stats
  # - None are boosted
  def should_eat?
    text = SkillsWindow.new.read_text
    # 
    # Make sure we can see all the stats
    [ 'Strength', 'Dexterity', 'Endurance', ].each do |s|
      return false unless text =~ Regexp.new("^#{s}")
    end
    return false if text.index('[')
    return true
  end

  def setup(parent)
    comps = [
      {:type => :point, :name => 'p', :label => 'Drag to click location'},
    ]
    @vals = UserIO.prompt(parent, nil, @name, comps)
  end

  def act
    x = @vals['p.x'].to_i
    y = @vals['p.y'].to_i
    loop do
      if should_eat?
	rclick_at(x, y)
	sleep_sec 5
	# If still not boosted, we're out of food.
	if should_eat?
	  puts "Out of food"
	  return
	end
      end
      sleep_sec 1
    end
  end

end
Action.add_action(Eat.new)


class FocusClick < Action
  def initialize
    super('Focus click', 'Misc')
  end

  def setup(parent)
    comps = [
      {:type => :point, :name => 'p', :label => 'Drag to click location'},
    ]
    @vals = UserIO.prompt(parent, nil, @name, comps)
  end

  def act
    x = @vals['p.x'].to_i
    y = @vals['p.y'].to_i
    loop do
      stat_wait('Foc')
      rclick_at_restore(x, y)
      sleep_sec 1
    end
  end
end
Action.add_action(FocusClick.new)

class ConClick < Action
  def initialize
    super('Constitution click', 'Misc')
  end

  def setup(parent)
    comps = [
      {:type => :point, :name => 'p', :label => 'Drag to click location'},
    ]
    @vals = UserIO.prompt(parent, nil, @name, comps)
  end

  def act
    x = @vals['p.x'].to_i
    y = @vals['p.y'].to_i
    loop do
      stat_wait('Con')
      rclick_at_restore(x, y)
      sleep_sec 1
    end
  end

end

Action.add_action(ConClick.new)
