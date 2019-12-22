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


  def reload(loom)
    if loom.click_on("Load the Loom with #{reload_what}")
      HowMuch.max
    end
  end    

  def restring(loom)
    if loom.click_on('Re-String')
      PopupWindow.dismiss
      loom.refresh
      sleep_sec(0.5)
      if loom.click_on('Load the Loom with Twine')
        HowMuch.max
      end
    end
  end

  def act
    loom = PinnableWindow.from_point(point_from_hash(@vals, 'loom'))
    loop do
      stat_wait('End')
      loom.refresh
      loom.click_on(weave_what)
      sleep_sec(0.5)

      loom.refresh
      restring loom
      PopupWindow.dismiss

      loom.refresh
      reload loom
      PopupWindow.dismiss
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

  def reload_what
    'Thread'
  end


end

class Canvas < Weave
  def initialize
    super('Weave Canvas')
  end

  def reload_what
    'Twine'
  end

  def weave_what
    'Weave Twine into Canvas'
  end

end
Action.add_action(Linen.new)
Action.add_action(Canvas.new)
