require 'action'

class DigStones < Action
  def initialize
    super('Dig Stones', 'Gather')
  end

  def setup(parent)
    comps = [
      {:type => :point, :name => 'p', :label => 'Drag to pinned Dig'},
    ]
    @vals = UserIO.prompt(parent, @name, @name, comps)
  end

  def act
    w = PinnableWindow.from_point(point_from_hash(@vals, 'p'))
    return unless w

    xy = [225, 65]
    loop do
      stat_wait(:end)
      p = mouse_pos
      w.click_on('Dig')
      mm(p)
      sleep(5)  # MAGIC Number.  Dig happens server side and lag.
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
      {:type => :text, :name => 'initial-delay', :label => 'One-time initial delay (default 0 sec)'},
      {:type => :text, :name => 'delay', :label => 'Min delay between clicks(default 5 sec)'},
    ]
    @vals = UserIO.prompt(parent, @name, @name, comps)
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
    init_delay = @vals['initial-delay'].to_i
    @delay = @vals['delay'].to_i
    @delay = 5 if @delay == 0
    stat_hotkeys(hotkeys.strip, @stats) if hotkeys.strip.size > 0

    sleep init_delay
    stat_clicks(@vals['p.x'].to_i, @vals['p.y'].to_i, @stats)
  end

  def stat_clicks(x, y, stats)
    stats = [stats] unless stats.kind_of?(Array)
    loop do
      # PopupWindow.dismiss
      stats.each { |stat| stat_wait(stat)}
      lclick_at(x, y)
      sleep @delay
    end
  end

end


class FocusClick < StatClicks
  def initialize
    super('Focus click', 'Misc')
    set_stats([:foc])
  end
end
Action.add_action(FocusClick.new)


class ConClick < StatClicks
  def initialize
    super('Constitution click', 'Misc')
    set_stats([:con])
  end
end

Action.add_action(ConClick.new)

class EnduranceClick < StatClicks
  def initialize
    super('Endurance click', 'Misc')
    set_stats([:end])
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
    @vals = UserIO.prompt(parent, @name, @name, comps)
  end

  def act
    pt = point_from_hash(@vals, 'p')
    win = PinnableWindow.from_point(pt)
    loop do
      stat_wait([:end, :str])
      win.refresh
      unless win.click_on('Stir the')
	sleep 5
      end
      sleep 1
    end
  end
end
Action.add_action(Stir.new)

class StrengthClick < StatClicks
  def initialize
    super('Strength click', 'Misc')
    set_stats([:str])
  end
end
Action.add_action(StrengthClick.new)

class Eat < Action
  def initialize
    super('Eat', 'Misc')
  end

  # Eat iff:
  # - No stats are boosted
  def should_eat?
    !stat_boosted?
  end

  def setup(parent)
    comps = [
      {:type => :point, :name => 'p', :label => 'Drag to pinned food'},
    ]
    @vals = UserIO.prompt(parent, @name, @name, comps)
  end

  def act
    x = @vals['p.x'].to_i
    y = @vals['p.y'].to_i
    w = PinnableWindow.from_point(Point.new(x, y))
    
    loop do
      if should_eat?
        w.refresh
        break if w.read_text.strip == ''
        eat(w) 
      end
      sleep 2
    end
  end

  # Return true if we think we ate.
  def eat(w)
    w.refresh
    text = w.read_text
    return false if text.include?('This is too far')

    # Don't know what a kitchen looks like yet. 
    if w.click_on 'Consume'
      sleep 5
      w.refresh
      return true
    else
      return false
    end
  end
end
Action.add_action(Eat.new)


class DismissPopups < Action
  def initialize
    super('Dismiss Popups', 'Misc')
  end

  def act
    loop do
      PopupWindow.dismiss
      sleep 0.5
    end
  end

end
Action.add_action(DismissPopups.new)


