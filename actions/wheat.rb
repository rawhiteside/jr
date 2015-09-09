require 'action'
require 'user-io'

class Wheat < GridAction
  def initialize
    super('Wheat', 'Plants')
  end

  def act_at(p)
    mm(p['x'],p['y'])
    sleep_sec 0.2
    send_string('hw')
  end
end
Action.add_action(Wheat.new)

