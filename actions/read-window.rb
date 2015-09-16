require 'action'
require 'window'
require 'actions/kettles'

class ReadWindow < Action
  def initialize(name = 'Read Window')
    super(name, 'Test/Dev')
  end

  def get_window(parent)
    gadgets = [{:type => :point, :label => 'Drag to location', :name => 'xy'}]
    h = UserIO.prompt(parent, nil, 'Read a pinnable', gadgets)
    return nil unless h
    ControllableThread.check_for_pause
    KettleWindow.from_point(point_from_hash(h, 'xy'))
    # PinnableWindow.from_point(point_from_hash(h, 'xy'))
  end

  def setup(parent)
    @window = get_window(parent)
  end

  def act
    text = @window.read_text
    comps = [
      {:type => :big_text, :value => text, :name => 'text'}
    ]
    UserIO.prompt(nil, 'Show results', 'Read this text', comps)

    puts ClockLocWindow.instance.read_text
    puts SkillsWindow.new.read_text
  end
end

Action.add_action(ReadWindow.new)
