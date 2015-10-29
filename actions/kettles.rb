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
    sleep_sec(0.1)
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

  def get_gadgets
    super << {:type => :combo, :label => 'Do what?', :name => 'action' ,
              :vals => ['Start and tend', 'Tend', ]}
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

  def pinned_kettle_window(p, pinned = true)
    w = PinnableWindow.from_screen_click(Point.new(p['x'], p['y']))
    w = KettleWindow.new(w.rect)
    w.pin if pinned
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

    repeat = @user_vals['repeat'].to_i
    task = @user_vals['action']

    repeat.times do 
      grid = GridHelper.new(@user_vals, 'g')

      done = {}
      grid.each_point { |p| done[p] = false }

      # Start them all cooking.
      if task =~ /Start/
        grid.each_point do |p|
          start_potash(p)
          done[p] = false
        end
      end

      # Tend until they're all done
      while done.values.include?(false)
        grid.each_point do |p|
          done[p] = tend_potash(p) unless done[p]
        end
        sleep_sec(3.0)
      end

      break unless task =~ /Start/

      # fill jugs
      rclick_at(224, 60)
      HowMuch.new(:max)
    end
  end

  # Look at the potash kettle at the point and decide what, if
  # anything, needs to be done. Return a true if the potash is
  # complete, false otherwise.
  def tend_potash(p)
    w = pinned_kettle_window(p, false)
    v = {}
    5.times do
      v = kettle_data(w)
      break if (v[:wood] && v[:water]) || v[:done]
      w.refresh
      sleep_sec (0.1)
    end
    
    unless (v[:wood] && v[:water]) || v[:done]
      puts "Didn't read kettle: "
      puts kettle_data(w)
    end

    if v[:done]
      w.pin
      w.click_button('take')
      w.unpin
      return true
    end

    if v[:wood] < 5 && v[:wood] < v[:water]
      w.click_on('Stoke')
    else
      w.pin
      w.unpin
    end
    return false
  end
  

end
Action.add_action(Potash.new)
