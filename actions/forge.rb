require 'action'

class ForgeAction < Action
  def initialize
    super("Forge", "Buildings")
  end

  def persistence_name
    'Forge'
  end
  def setup(parent)
    comps = [
      {:type => :grid, :name => 'g'},
      {:type => :text, :name => 'what', :size => 20,
	:label => 'Make what? '},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, comps)
  end

  def act
    tiler = Tiler.new(0, 30, 0)
    windows = []
    # Assume the forges filled and started.
    loop do
      GridHelper.new(@vals, 'g').each_point do |p|
	# Wait till it's ready
	w = PinnableWindow.from_screen_click(Point.new(p['x'].to_i, p['y'].to_i))
	w.pin
	loop do
	  w.refresh
	  text = w.read_text
	  if text =~ /Make a/
	    w.unpin
	    w = PinnableWindow.from_screen_click(Point.new(p['x'].to_i, p['y'].to_i))
	    break
	  end
	  sleep_sec 5.0
	end
	# Click on the item
	w.click_on(@vals['what'])
	w.unpin
      end
    end
  end
end
  Action.add_action(ForgeAction.new)
