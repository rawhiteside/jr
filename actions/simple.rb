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
    @vals = UserIO.prompt(parent, 'Interval keys', 'Interval keys', gadgets)
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
      ControllableThread.check_for_pause
      if @if_tab
        send_vk(VK_TAB)
      else
        send_string @key
      end
    end
  end
  
end

Action.add_action(IntervalTab.new)
