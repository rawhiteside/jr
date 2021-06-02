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

  def act_at(ginfo)
    mm(ginfo['x'], ginfo['y'])
    sleep 0.1
    send_string(@user_vals['string'], 0.1)
  end
end
Action.add_action(Bricks.new)
