require 'action'
require 'window'

class KettleAction < GridAction
  def initialize(n)
    super(n, 'Buildings')
    yoff = 26
    @locs = {
      'Take' => [42, 256],
      'Begin' => [42, 256],
      'Potash' => [42, 180],
      'Flower Fert' => [42, 206],
      'Weed Killer' => [126, 180],
      'Grain Fert' => [126, 206],
    }
    @locs.each_key {|k| @locs[k][1] -= yoff }
  end
end

class Fert < KettleAction
  def initialize
    super('Grain Fertilizer')
  end

  def act_at(g)
    w = PinnableWindow.from_screen_click(Point.new(g['x'], g['y']))
    w.dialog_click(Point.new(*@locs['Take']))
    sleep_sec 0.1
    w.dialog_click(Point.new(*@locs['Grain Fert']))
    sleep_sec 0.1
    w.dialog_click(Point.new(*@locs['Begin']))
    sleep_sec 0.1
    AWindow.dismiss_all
  end
end
Action.add_action(Fert.new)

class FlowerFert < KettleAction
  def initialize
    super('Flower Fertilizer')
  end

  def act_at(g)
    w = PinnableWindow.from_screen_click(Point.new(g['x'], g['y']))
    # w.dialog_click(Point.new(*@locs['Take']))
    # sleep_sec 0.1
    w.dialog_click(Point.new(*@locs['Flower Fert']))
    sleep_sec 0.1
    w.dialog_click(Point.new(*@locs['Begin']))
    sleep_sec 0.1
    AWindow.dismiss_all
  end
end
Action.add_action(FlowerFert.new)


class TakeFromKettles < KettleAction
  def initialize
    super('Take from kettles')
  end

  def act_at(g)
    w = PinnableWindow.from_screen_click(Point.new(g['x'], g['y']))
    w.dialog_click(Point.new(*@locs['Take']))
    sleep_sec 0.1
    AWindow.dismiss_all
  end
end
Action.add_action(TakeFromKettles.new)


class KettleWindow < PinnableWindow

  def initialize(rect)
    super
    yoff = 26
    @locs = {

      'take' => [42, 256],
      'begin' => [42, 256],
      'ignite' => [42, 256],
      'arsenic' => [42, 256],

      'potash' => [42, 180],
      'weed killer' => [126, 180],
      'grain fert' => [126, 206],
    }
    @locs.each_key {|k| @locs[k][1] -= yoff }
  end

  def click_button(which)
    dialog_click(*@locs[which.downcase])
  end

  # Area holding menu text
  DATA_HEIGHT = 160
  def text_rectangle
    rect = super
    rect.height -= DATA_HEIGHT
    rect
  end

  def data_text_reader
    TextReader.new(data_rect)
  end

  def read_data
    data_text_reader.read_text
  end

  def data_rect
    tr = text_rectangle
    data_area_border_thickness = 4
    # Measured on the screen.
    data_area_height = 93
    # Move in this far from left and right. 
    off = 13
  
    Rectangle.new(@rect.x + off,
		  tr.y + tr.height + data_area_border_thickness,
		  @rect.width - (2 * off),
		  data_area_height)
  end
end

class Potash < KettleAction
  def initialize
    super('Potash')
  end

  def act_at(g)
  end
end
