require 'action'
require 'window'
require 'actions/kettles'

class ReadWindow < Action
  def initialize(name = 'Read Window')
    super(name, 'Test/Dev')
  end


  def setup(parent)
    gadgets = [
      {:type => :checkbox, :label => 'Chat Window', :name => 'chat-history-p' },
      {:type => :checkbox, :label => 'ClockLoc', :name => 'clock-loc-p' },
      {:type => :checkbox, :label => 'Skills', :name => 'skills-p' },
      {:type => :checkbox, :label => 'Inventory', :name => 'inventory-p' },
      {:type => :checkbox, :label => 'Pinnable window', :name => 'pinnable-p' },
      {:type => :point, :label => 'Drag to Pinnable if checked', :name => 'xy'},
      
    ]
    @vals = UserIO.prompt(parent, nil, action_name, gadgets)
  end

  def show_text(text, title)
    comps = [
      {:type => :big_text, :rows => 20, :cols => 60, :value => text, :name => 'text', :label => title}
    ]
    UserIO.prompt(nil, nil, title, comps)

  end

  def act
    dim = screen_size
    if @vals['pinnable-p'] == 'true'
      w = PinnableWindow.from_point(point_from_hash(@vals, 'xy'))
      show_text(w.read_text, 'Pinnable')
    end


    if @vals['clock-loc-p'] == 'true'
      cl = ClockLocWindow.instance
      text = cl.read_text
      puts text
      coords = cl.coords
      text += "\nWorld Coordinates: #{coords[0]}, #{coords[1]}\n"
      text += "\nDate: #{cl.date}\n"
      text += "\nTime: #{cl.time}\n"
      text += "\nDateTime: #{cl.date_time}\n"
      show_text(text, 'ClockLoc')
    end
    
    if @vals['skills-p'] == 'true'
      skills = SkillsWindow.new
      show_text(skills.read_text, 'Skills')
    end
      

    if @vals['chat-history-p'] == 'true'
      dim = screen_size
      chat = ChatWindow.find
      show_text(chat.read_text, 'Chat history')
    end
    
    if @vals['inventory-p'] == 'true'
      # about my usual spot
      inventory = InventoryWindow.find
      show_text(inventory.read_text, 'Inventory')
    end
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
