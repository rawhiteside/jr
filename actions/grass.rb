require 'action'
require 'walker'

class CasualGrass < Action
  
  def initialize
    super('Casual Grass', 'Gather')
  end

  def act
    pixel = 0x020ae05
    xy = [93, 56]
    loop do
      if pixel == get_pixel(*xy)
	rclick_at_restore(xy[0], xy[1])
	sleep_sec 0.5
      else
	Thread.pass
      end
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
    @path = [
      [4563, -5827], 
      [4561, -5827], 
    ]
  end

  def start_grass_watcher
    @threads << ControllableThread.new {CasualGrass.new.act}
  end


  def setup(parent)
    gadgets = [
      {:type => :point, :name => 'chest', :label => 'Stash chest window'},
      {:type => :number, :name => 'count', :label => 'How many loops till stash? '},
      {:type => :world_path, :label => 'Path to walk', :name => 'path'}
    ]
    @vals = UserIO.prompt(parent, 'Grass', 'Grass', gadgets)
    return nil unless @vals
    @stash_window = PinnableWindow.from_point(point_from_hash(@vals, 'chest'))
    @path_count = @vals['count'].to_i
    @path = WorldLocUtils.parse_world_path(@vals['path'])
    @vals
  end

  def act
    @walker.walk_to(@path[0])
    start_grass_watcher
    loop do
      @walker.walk_loop(@path, @path_count)
      @stash_window.click_on('Stash/Grass')
      HowMuch.new(:max)
      @stash_window.refresh
    end
  end

  def stop
    puts 'Stop called'
    @threads.each {|t| t.kill}
    super
  end
end

Action.add_action(Grass.new)
Action.add_action(CasualGrass.new)
