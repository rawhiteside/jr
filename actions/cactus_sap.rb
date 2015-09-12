require 'action'

class CactusSap < Action

  def initialize
    super('Cactus Sap (2)', 'Gather')
  end

  def find_windows
    y = 70
    x = 60

    windows = []
    w = find_one_window(x, y)
    windows << w

    y = w.rect.y + w.rect.height + 30 
    w = find_one_window(x, y)
    windows << w

    windows
  end

  def find_one_window(x, y)
    w = PinnableWindow.from_point(Point.new(x, y))
    unless w
      msg = 'Missed a pinned cactus dialog'
      UserIO.error(msg)
      raise Exception.new(msg)
    end
    w

  end

  def act
    windows = find_windows
    loop do
      windows.each do |w|
	w.refresh
	if w.read_text =~ /3 drops/
	  3.times {w.click_on('Collect'); sleep_sec 1}
	end
      end
      sleep_sec 30
    end
  end
end
Action.add_action(CactusSap.new)
