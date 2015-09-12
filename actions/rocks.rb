require 'action'

class Cutstones < GridAction
  def initialize
    super('Cutstones', 'Buildings')
  end

  def act
    # ChatLineWindow.new.minimize
    super
  end

  def act_at(p)
    with_robot_lock do
      mm(p['x'],p['y'])
      sleep_sec 0.2
      send_string('c')
    end
  end
end

Action.add_action(Cutstones.new)

class Crucibles < GridAction
  def initialize
    super('Crucibles', 'Buildings')
  end

  def act_at(p)
    with_robot_lock do
      mm(p['x'],p['y'])
      sleep_sec 0.2
      send_string('c')
    end
  end
end
Action.add_action(Crucibles.new)
