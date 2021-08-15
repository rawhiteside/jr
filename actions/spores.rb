require 'action'

class SporePapers < Action

  def initialize
    super('Spore papers', 'Misc')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'The pinned Inspect button', :name => 'inspect'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    pt = point_from_hash(@vals, 'inspect')
    win = PinnableWindow.from_point(pt)
    loop do
      stat_wait :foc
      with_robot_lock do
        win.click_on('Inspect')
        sleep 0.5
        popup = PopupWindow.find
        text = popup.read_text
        lines = text.split("\n")
        break if lines.size < 3
        popup.click_on(lines[1])
        sleep 0.5
        popup.click_on("OK")
        sleep 5
        
        result = PopupWindow.find
        sleep 0.5
        result.click_on("OK")
        sleep 5
      end
    end
  end
end
Action.add_action(SporePapers.new)

