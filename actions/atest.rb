require 'action'
require 'window'
require 'actions/kettles'

class ATest < Action

  def initialize(name = 'Test Build Gadget')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    gadgets = [{:type => :point, :label => 'Drag to planbt location', :name => 'plant'}]
    @vals = UserIO.prompt(parent, nil, 'Test the build gadget', gadgets)
  end

  def act
    b = BuildMenu.new
    
    rclick_at(point_from_hash(@vals, 'plant'))
    [
      :w, :w, :W, :E, :e, :w,
      :l, :l, :l, :L, :L, :L,
      :r, :r, :r, :R, :R, :R,
      :n, :N, :s, :S,
    ].each { |d|
      rclick_at(*(BuildMenu::BUTTONS[d]));
      sleep_sec(1)
    }
  end
end


Action.add_action(ATest.new)
