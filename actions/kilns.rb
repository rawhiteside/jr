require 'action'
require 'user-io'

class Kilns < GridAction
  def initialize(name='Kilns', group='Buildings')
    super(name, group)
  end

  def get_gadgets
    super +
      [{:type => :text, :label => 'String to send', :name => 'string'},
       {:type => :number, :label => 'Key delay', :name => 'key-delay'}]
  end

  def act_at(p)
    
    mm(p['x'],p['y'])
    sleep_sec 0.1
    send_string(@user_vals['string'], @user_vals['key-delay'].to_f)
  end
end

Action.add_action(Kilns.new)

class PotteryWheel < Kilns
  def initialize
    super('Pottery Wheels', 'Buildings')
  end
  def act_at(p)
    
    mm(p['x'],p['y'])
    sleep_sec 0.3
    send_string(@user_vals['string'], @user_vals['key-delay'].to_f)
  end
end
Action.add_action(PotteryWheel.new)


