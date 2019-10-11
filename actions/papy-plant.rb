require 'action'
require 'walker'

class PlantPapy < Action
  def initialize
    super('Plant Papyrus', 'Plants')
  end

  def setup(parent)
    gadgets = 
      [
        {:type => :point, :name => 'plant', :label => 'Plant window',},
        {:type => :world_path, :label => "Plant locations", :name => "coords",},
        {:type => :number, :name => 'delay', :label => 'Delay secs'},
      ]

    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)

  end

  def act
    path = WorldLocUtils.parse_world_path(@vals['coords'])
    win = PinnableWindow.from_point(point_from_hash(@vals, 'plant'))
    delay = @vals['delay'].to_i
    walker = Walker.new
    loop do
      walker.walk_loop(path) do
        win.click_on('Papyrus')
        sleep_sec(delay)
      end
    end

  end
  
end

Action.add_action(PlantPapy.new)
