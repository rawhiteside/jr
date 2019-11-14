require 'action'

class DigStones < Action
  def initialize
    super('Dig Stones', 'Gather')
  end

  def setup(parent)
    comps = [
      {:type => :point, :name => 'p', :label => 'Drag to pinned Dig'},
    ]
    @vals = UserIO.prompt(parent, nil, action_name, comps)
  end

  def act
    w = PinnableWindow.from_point(point_from_hash(@vals, 'p'))
    return unless w

    xy = [225, 65]
    loop do
      stat_wait('End')
      p = mouse_pos
      w.click_on('Dig')
      mm(p)
      sleep_sec(10)  # MAGIC.  Dig happens server side and lag.
    end
  end
end
Action.add_action(DigStones.new)

class StatClicks < Action
  def setup(parent)
    comps = [
      {:type => :point, :name => 'p', :label => 'Drag to click location'},
      {:type => :label, :label => '~ Or ~'},
      {:type => :text, :name => 'hotkeys', :label => 'Hotkeys (has priority)'},
      {:type => :text, :name => 'delay', :label => 'Delay (for lag)'},
    ]
    @vals = UserIO.prompt(parent, nil, @name, comps)
  end

  def set_stats(stats)
    stats = [stats] unless stats.kind_of?(Array)
    @stats = stats
  end
  
  def stat_hotkeys(str, stats)
    stats = [stats] unless stats.kind_of?(Array)
    loop do
      PopupWindow.dismiss
      stats.each { |stat| stat_wait(stat)}
      sleep @delay
      send_string(str)
    end
  end

  def act
    hotkeys = @vals['hotkeys']
    @delay = @vals['delay'].to_i
    @delay = 5 if @delay == 0
    stat_hotkeys(hotkeys.strip, @stats) if hotkeys.strip.size > 0
    stat_clicks(@vals['p.x'].to_i, @vals['p.y'].to_i, @stats)
  end

  def stat_clicks(x, y, stats)
    stats = [stats] unless stats.kind_of?(Array)
    loop do
      # PopupWindow.dismiss
      stats.each { |stat| stat_wait(stat)}
      sleep_sec @delay
      rclick_at(x, y)
    end
  end

end


class FocusClick < StatClicks
  def initialize
    super('Focus click', 'Misc')
    set_stats(['Foc'])
  end
end
Action.add_action(FocusClick.new)


class ConClick < StatClicks
  def initialize
    super('Constitution click', 'Misc')
    set_stats(['Con'])
  end
end

Action.add_action(ConClick.new)

class EnduranceClick < StatClicks
  def initialize
    super('Endurance click', 'Misc')
    set_stats(['End'])
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
	sleep_sec 5
      end
      sleep_sec 1
    end
  end
end
Action.add_action(Stir.new)

class StrengthClick < StatClicks
  def initialize
    super('Strength click', 'Misc')
    set_stats(['Str'])
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
    [ 'Strength', 'Dexterity', 'Endurance', 'Speed', 'Constitution', 'Focus'].each do |s|
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
    w = PinnableWindow.from_point(Point.new(x, y))
    
    loop do
      if should_eat?
        break if eat(w).nil? 
      end
      sleep_sec 2
    end
  end

  def eat(w)
    w.refresh
    text = w.read_text
    return true if text.include?('This is too far')

    if text.include?('Kitchen')
      with_robot_lock do
        w.click_on 'Enjoy'
        sleep 5
        w.refresh
        return true
      end
    else
      return w.click_on 'Eat'
    end
  end
end
Action.add_action(Eat.new)


