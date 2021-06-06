require 'action'

class IntervalTab < Action
  def initialize
    super("Inverval keys", "Misc")
  end

  def setup(parent)
    gadgets = [{:type => :text, :label => 'Secs between keys', :name => 'interval'},
               {:type => :combo, :name => 'tab-or-key', :label => 'What keys?',
                :vals => ['Tab', 'Provided key']},
               {:type => :text, :label => 'Key', :name => 'key'}
              ]
    @vals = UserIO.prompt(parent, name, 'Interval keys', gadgets)
    return nil unless @vals
    @delay = @vals['interval'].to_f
    @key = @vals['key']
    @if_tab = (@vals['tab-or-key'] == 'Tab')
    true
  end

  def act
    return unless @delay > 0

    loop do
      sleep @delay
      check_for_pause
      if @if_tab
        send_vk(VK_TAB)
      else
        send_string @key
      end
    end
  end
  
end

Action.add_action(IntervalTab.new)


class IntervalClicks < Action
  def initialize
    super("Inverval clicks", "Misc")
  end

  def setup(parent)
    gadgets = [{:type => :text, :label => 'Secs between clicks', :name => 'interval'},
               {:type => :point, :label => 'Click location', :name => 'xy'},
              ]
    @vals = UserIO.prompt(parent, name, 'Interval keys', gadgets)
    return nil unless @vals
    @delay = @vals['interval'].to_f
    true
  end

  def act
    return unless @delay > 0

    pt = point_from_hash(@vals, 'xy')
    loop do
      lclick_at_restore(pt)
      sleep @delay
    end
  end
  
end

Action.add_action(IntervalClicks.new)
