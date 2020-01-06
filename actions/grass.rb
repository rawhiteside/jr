require 'action'
require 'walker'

class CasualGrass < Action
  
  def initialize
    super('Casual Grass', 'Gather')
  end

  def act
    loop do
      send_string "1"
      sleep 0.5
    end
  end
end

class Grass < Action
  def initialize
    super('Grass', 'Gather')
    @threads = []
    @walker = Walker.new
    @pause = false
    @stash_window = nil
  end

  def start_grass_watcher
    @threads << ControllableThread.new {CasualGrass.new.act}
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :name => 'chest', :label => 'Stash chest window'},
      {:type => :world_loc, :name => 'chest-coords', :label => 'Coordinates within reach of the chest.'},
      {:type => :number, :name => 'count', :label => 'How many loops till stash? '},
      {:type => :world_path, :label => 'Path to walk', :name => 'path'}
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
    return nil unless @vals
    @path_count = @vals['count'].to_i
    @path = WorldLocUtils.parse_world_path(@vals['path'])
    @chest_coords = WorldLocUtils.parse_world_location(@vals['chest-coords'])
    @vals
  end

  def act
    @stash_window = PinnableWindow.from_point(point_from_hash(@vals, 'chest')) unless @stash_window
    @walker.walk_to(@path[0])
    start_grass_watcher
    loop do
      @walker.walk_loop(@path, @path_count)
      @walker.walk_to(@chest_coords)
      @stash_window.refresh
      unless @stash_window.click_on('Stash/Grass')
        puts "Stash failed:"
        puts @stash_window.read_text
      end
      HowMuch.max
    end
  end

  def stop
    @threads.each {|t| t.kill}
    super
  end
end

Action.add_action(Grass.new)
Action.add_action(CasualGrass.new)
