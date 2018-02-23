require 'action'
require 'timer'
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

class TimeTest < Action

  def initialize(name = 'Time something (change code for target)')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    true
  end

  def act

    rect = nil
    num_times = 100
    elapsed = nil
    
    elapsed = Timer.time_this do
      num_times.times do
        rect = WindowGeom.rectFromPoint(Point.new(50, 50))
        if rect.nil?
          puts "failed"
          break
        end
      end

    end
    once = elapsed / num_times
    puts "Num_times = #{num_times}, total = #{elapsed}, once = #{once}"
  end
end


Action.add_action(TimeTest.new)
