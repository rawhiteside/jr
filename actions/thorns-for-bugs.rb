require 'action'
require 'walker'

class ThornRun < Action
  def initialize
    super('Thorn run 2', 'Gather')
  end

  def find_one_window(x, y)
    w = PinnableWindow.from_point(Point.new(x, y))
    unless w
      msg = 'Missed a pinned thorn dialog'
      UserIO.error(msg)
      raise Exception.new(msg)
    end
    w
  end

  def find_windows
    left_count = 10
    mid_count = 3
    @windows = []
    x = 60
    y = 70
    left_count.times do |i|
      w = find_one_window(x, y)
      @windows << w
      y = w.rect.y + w.rect.height + 30
    end
    x = 280
    y = 70
    mid_count.times do |i|
      w = find_one_window(x, y)
      @windows << w
      y = w.rect.y + w.rect.height + 30
    end
    return @windows
  end

  # Need to wait until the thorn actuall gets harvested.  Refresh it
  # until we fine the word "More"
  def wait_for_more(w)
    6.times do
      sleep_sec 0.5
      w.refresh
      return true if w.read_text =~ /More/
    end
    return false
  end

  def harvest(w)
    loop do
      w.refresh
      if w.click_on('Gather')
	return if wait_for_more(w)
      end
    end
  end

  def persistence_name
    'Thorns'
  end
  def get_drop_window(parent)
    comps = [
      {:type => :point, :name => 'drop', :label => 'Pinned drop menu'},
    ]
    vals = UserIO.prompt(parent, persistence_name, action_name, comps)
    return nil unless vals
    w = PinnableWindow.from_point(point_from_hash(vals, 'drop'))
    return w
  end

  def thorn_paths
    [
      # First thorn is at [4431, -5853]
      nil,
      nil,
      nil,
      nil,
      nil,
      [4439, -5845],
      nil,
      nil,
      [4447, -5841],
      nil,
      nil,
      nil,
      
      # back to beginning.
      [4431, -5853],
    ]
  end


  def setup(parent)
    @drop = get_drop_window(parent)
  end

  def act
    walker = Walker.new
    windows = find_windows
    
    loop do
      paths = thorn_paths
      windows.each do |w|
	harvest(w)
	path = paths.shift
	if path
	  # Convenience, so we canput just coords into the thorn_paths list
	  path = [path] unless path[0].kind_of?(Array)
	  walker.walk_path(path)
	end
      end
      @drop.refresh
      @drop.click_on('Thorns')
      HowMuch.new(:max)
    end
    
  end
end

Action.add_action(ThornRun.new)

