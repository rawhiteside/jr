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
      {:type => :big_text, :rows => 20, :cols => 60, :value => text, :name => 'text', :label => 'Text'}
    ]
    UserIO.prompt(nil, nil, 'Read this text', comps)

    return
    cl = ClockLocWindow.instance
    puts "World coordinates: (#{cl.coords[0]}, #{cl.coords[1]})"
    

    skills = SkillsWindow.new
    # skills.display_to_user("Skills window")
    puts "===================== Skills Window"
    puts skills.read_text

    chat = ChatWindow.from_point(Point.new(1800, 1000))
    puts "======================== Chat Window"
    puts chat.read_text
    
    # about my usual spot
    puts "========================= Inventory Window"
    inventory = InventoryWindow.from_point(Point.new(260, 950))
    puts inventory.read_text
  end
end
Action.add_action(ReadWindow.new)

class KettleTest < Action
  def initialize(name = 'Kettle test')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    gadgets = [{:type => :point, :label => 'Drag to location', :name => 'xy'}]
    @vals = UserIO.prompt(parent, nil, action_name, gadgets)
  end

  def act
    w = PinnableWindow.from_point(point_from_hash(@vals, 'xy'))
    puts w.read_text
    ['Potash', 'Weed', 'Flower', 'Grain', 'Salt', 'Sulfur', 'Sulfuric' ].each do |button|
      point = w.coords_for_word(button)
      if point
        mm(point)
      else
        puts "Didn't find #{button}"
      end
        sleep 1
    end
  end

end
Action.add_action(KettleTest.new)
