require 'action'
require 'window'
require 'actions/kettles'

class ReadWindow < Action
  def initialize(name = 'Read Window')
    super(name, 'Test/Dev')
  end


  def setup(parent)
    gadgets = [{:type => :point, :label => 'Drag to location', :name => 'xy'}]
    @vals = UserIO.prompt(parent, nil, action_name, gadgets)
  end

  def act

    w = PinnableWindow.from_point(point_from_hash(@vals, 'xy'))
    @window = KettleWindow.new(w.rect)

    text = @window.read_text
    comps = [
      {:type => :big_text, :value => text, :name => 'text', :label => 'Text'}
    ]
    UserIO.prompt(nil, nil, 'Read this text', comps)

    cl = ClockLocWindow.instance
    puts cl.coords[0]
    puts cl.coords[1]
    

    # puts SkillsWindow.new.read_text
  end
end

Action.add_action(ReadWindow.new)
