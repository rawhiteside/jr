require 'action'

class Weave < Action
  def initialize(n)
    super(n, 'Buildings')
  end

  def setup(parent)
    comps = [
      {:type => :point, :name => 'loom', :label => 'Pinned loom.'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, comps)
  end

  def act
    loom = PinnableWindow.from_point(point_from_hash(@vals, 'loom'))
    loop do
      stat_wait('End')
      loom.refresh
      loom.click_on(weave_what)
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
    loom = PinnableWindow.from_point(point_from_hash(@vals, 'loom'))
    puts loom.read_text
    loop do
      stat_wait('End')
      loom.refresh
      loom.click_on(weave_what)
      sleep_sec(0.5)
      loom.refresh
      if loom.click_on('Re-String')
        p = PopupWindow.find
        p.dismiss if p
        loom.refresh
        sleep_sec(0.5)
        if loom.click_on('Load the Loom with Twine')
          HowMuch.max
        end
      end

      loom.refresh
      if loom.click_on('Load the Loom with Thread')
	HowMuch.max
      end
      p = PopupWindow.find
      p.dismiss if p
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
