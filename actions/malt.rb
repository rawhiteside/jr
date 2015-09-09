require 'action'

class MaltingTrays < GridAction
  def initialize
    super('Malt barley', 'Buildings')
  end

  def wait_for_no_germinate(w)
    loop do
      w.refresh
      break unless w.read_text =~ /germinat/
      sleep_sec 5
    end
  end

  def take(w)
      return unless w.read_text =~ /Take/
      w.click_on('Take/Everything')
  end

  def act_at(p)
    sleep_sec 0.5
    w = PinnableWindow.from_screen_click(Point.new(p['x'],p['y'])).pin
    return unless w
    wait_for_no_germinate(w)
    take(w)
    w.unpin
    mm(p['x'],p['y'], 0.1)
    send_string('m')
  end
end

Action.add_action(MaltingTrays.new)
