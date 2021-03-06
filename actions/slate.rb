require 'action'
require 'walker'

class CasualDowse < Action
  def initialize
    super('Casual Dowse', 'Gather')
  end

  def act
    loop do
      Icons.hotkey_if_active(:dowse)
      sleep 1
    end
  end
end

class CasualSlate < Action
  def initialize
    super('Casual Slate', 'Gather')
  end

  def act
    loop do
      send_string '8'
      sleep 0.2
    end
  end
end

class Slate < Action
  def initialize
    super('Slate', 'Gather')
    @walker = Walker.new
  end

  def start_slate_watcher
    start_worker_thread { CasualSlate.new.act }
  end

  def setup(parent)
    gadgets = 
      [
        :type => :world_path, :label => "Slate path", :name => "coords",
      ]
    vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)

    return nil unless vals

    @loop = WorldLocUtils.parse_world_path(vals['coords'])
    true
  end

  def act
    check_for_pause
    @walker.walk_to(@loop[0])
    start_slate_watcher
    @walker.walk_loop(@loop, 9999)
  end

end

Action.add_action(Slate.new)
Action.add_action(CasualSlate.new)
Action.add_action(CasualDowse.new)
