require 'action'
require 'window'

class Thorns < Action
  def initialize
    super("Thorns", "Gather")
    @windows = []
  end

  def find_one_window(x, y)
    w = PinnableWindow.from_point(Point.new(x, y))
    unless w
      msg = 'Missed a pinned thorn dialog'
      UserIO.error(msg)
      raise Exception.new(msg)
    end
    w
  end

  def get_windows
    @windows = []
    x = 70
    y = 80
    7.times do
      w = find_one_window(x, y)
      @windows << w
      y = w.rect.y + w.rect.height*2  - 10
    end
  end

  def harvest(w)
    # Wait until it's ready for harvest
    loop do
      w.refresh
      break if w.read_text =~ /Gather/
      sleep_sec 1
    end
    w.click_on("Gather")
    sleep_sec 1
    # Wait until it's been harvested before going on
    # to the next.
    loop do
      w.refresh
      break unless w.read_text =~ /Gather/
      sleep_sec 1
    end
  end


  def act
    return unless get_windows

    ControllableThread.check_for_pause
    loop do
      @windows.each { |w| harvest(w)}
    end
  end
end

Action.add_action(Thorns.new)

