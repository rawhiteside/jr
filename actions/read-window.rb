require 'action'
require 'window'
require 'actions/kettles'

class ReadWindow < Action
  def initialize(name = 'Read Window')
    super(name, 'Test/Dev')
  end


  def setup(parent)
    gadgets = [{:type => :point, :label => 'Drag to location', :name => 'xy'}]
    @vals = UserIO.prompt(parent, nil, 'Read a pinnable', gadgets)
  end

  def act

    w = PinnableWindow.from_point(point_from_hash(@vals, 'xy'))
    @window = KettleWindow.new(w.rect)

    text = @window.read_text
    comps = [
      {:type => :big_text, :value => text, :name => 'text', :label => 'Text'}
    ]
    UserIO.prompt(nil, nil, 'Read this text', comps)

    if @window.respond_to?(:read_data)
      data = @window.read_data

      comps = [
        {:type => :big_text, :value => data, :name => 'text', :label => 'Data'}
      ]
      UserIO.prompt(nil, nil, 'Read this data', comps)
    end

    puts ClockLocWindow.instance.read_text
    puts SkillsWindow.new.read_text
  end
end

Action.add_action(ReadWindow.new)
