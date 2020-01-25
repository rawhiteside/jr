require 'action'

class Cutstones < GridAction
  def initialize
    super('Cutstones', 'Buildings')
  end

  def act
    super
  end

  def act_at(ginfo)
    with_robot_lock do
      mm(ginfo['x'], ginfo['y'])
      sleep 0.2
      send_string('c')
    end
  end
end

Action.add_action(Cutstones.new)

class Crucibles < GridAction
  def initialize
    super('Crucibles', 'Buildings')
  end

  def act_at(ginfo)
    with_robot_lock do
      mm(ginfo['x'], ginfo['y'])
      sleep 0.2
      send_string('c')
    end
  end
end
Action.add_action(Crucibles.new)
