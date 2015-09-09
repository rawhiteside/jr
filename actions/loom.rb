require 'action'

class Weave < Action
  def initialize(n)
    super(n, 'Buildings')
  end

  def get_loom_window(parent)
    comps = [
      {:type => :point, :name => 'loom', :label => 'Pinned loom.'},
    ]
    vals = UserIO.prompt(parent, 'Loom', 'Loom', comps)
    return unless vals

    PinnableWindow.from_point(point_from_hash(vals, 'loom'))
  end

  def setup(parent)
    @loom = get_loom_window(parent)
  end

  def act
    loop do
      stat_wait('End')
      @loom.refresh
      @loom.click_on(weave_what)
      sleep 0.5
    end
  end
end


class Linen < Weave
  def initialize
    super('Weave Linen')
  end

  def weave_what
    'Weave Thread into Linen'
  end


  def act
    loop do
      stat_wait('End')
      @loom.refresh
      @loom.click_on(weave_what)
      sleep_sec(0.5)
      if @loom.click_on('Load the Loom with Thread')
	HowMuch.new(:max)
      end
    end
  end

end

class Canvas < Weave
  def initialize
    super('Weave Canvas')
  end

  def weave_what
    'Weave Twine into Canvas'
  end

end
Action.add_action(Linen.new)
Action.add_action(Canvas.new)
