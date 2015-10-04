require 'action'
require 'window'
require 'actions/kettles'

class ATest < Action

  def initialize(name = 'Test Wait for minimized chat')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    true
  end

  def act
    WindowGeom.wait_for_chat_minimized
  end
end


Action.add_action(ATest.new)
