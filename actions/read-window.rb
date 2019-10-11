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

    dim = screen_size
    puts dim.width/2
    puts dim.height
    w = PinnableWindow.from_point(point_from_hash(@vals, 'xy'))

    text = w.read_text
    puts text
    comps = [
      {:type => :big_text, :value => text, :name => 'text', :label => 'Text'}
    ]
    UserIO.prompt(nil, nil, 'Read this text', comps)

    cl = ClockLocWindow.instance
    puts "World coordinates: (#{cl.coords[0]}, #{cl.coords[1]})"
    

    skills = SkillsWindow.new
    skills.display_to_user("Skills window")
    puts skills.read_text

  end
end

Action.add_action(ReadWindow.new)
