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
    xy = @locs[which.downcase]
    dialog_click(Point.new(xy[0], xy[1]), 'tc')
  end

  # Area holding menu text
  DATA_HEIGHT = 160
  def text_rectangle
    rect = super
    rect.height -= DATA_HEIGHT
    rect
  end

  def read_data
    text = nil
    with_robot_lock do
      refresh
      data_text_reader = TextReader.new(data_rect)
      text = data_text_reader.read_text
    end
    text
  end

  def data_rect
    tr = text_rectangle
    data_area_border_thickness = 10
    # Measured on the screen.
    data_area_height = 93
    # Move in this far from left and right. 
    off = 13
  
    r = Rectangle.new(tr.x + off,
		  tr.y + tr.height + data_area_border_thickness,
		  tr.width,  # No offset here, as the pin exclusion.
		  data_area_height)
    return r
  end


end

class Potash < KettleAction
  def initialize
    super('Potash')
  end

  # The useful numbers in the data area.
  # vals[:water] and vals[:wood]
  def kettle_data(w)
    vals = {}
    text = w.read_data
    match = Regexp.new('Wood: ([0-9]+)').match(text)
    vals[:wood] = match[1].to_i if match
    match = Regexp.new('Water: ([0-9]+)').match(text)
    vals[:water] = match[1].to_i if match
    vals[:done] = (text =~ /The recipe is complete/)
    
    vals
  end

  def pinned_kettle_window(p)
    w = PinnableWindow.from_screen_click(Point.new(p['x'], p['y']))
    w = KettleWindow.new(w.rect)
    w.pin
    w
  end

  def start_potash(p)
    w = pinned_kettle_window(p)
    w.click_button('potash')
    w.click_button('begin')
    w.click_button('ignite')
    HowMuch.new(:max)
    w.unpin
  end


  def act

    grid = GridHelper.new(@user_vals, 'g')

    # Start them all cooking.
    done = {}
    grid.each_point do |p|
      sleep_sec(1)
      start_potash(p)
      done[p] = false
    end

    while done.values.include?(false)
      grid.each_point do |p|
        w = pinned_kettle_window(p)
        done[p] = tend_potash(w) unless done[p]
        w.unpin
        sleep 1
      end
    end
  end

  # Look at the potash window and decide what, if anything, needs to
  # be done. Return a true if the potash is complete, false otherwise.
  def tend_potash(w)
    v = kettle_data(w)
    
    if v[:done]
      w.click_button('take')
      return true
    end
    if v[:wood] < 5 && v[:wood] < v[:water]
      w.click_on('Stoke')
    end
    return false
  end
  

end
Action.add_action(Potash.new)
