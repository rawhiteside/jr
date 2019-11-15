require 'action'
require 'window'

class KettleAction < GridAction
  def initialize(n)
    super(n, 'Buildings')
  end
end

class Fert < KettleAction
  def initialize
    super('Grain Fertilizer')
  end

  def start_pass(index)
    @first_pass = (index == 0)
  end
  
  def act_at(g)
    delay = 0.3
    unless @first_pass
      w.click_button('Take')
      sleep_sec delay
    end
    w = KettleWindow.from_screen_click(g['x'], g['y'])
    w.click_button('Grain Fert' )
    sleep_sec delay
    w.click_button('Begin')
    sleep_sec delay
    AWindow.dismiss_all
    sleep_sec delay
  end
end
Action.add_action(Fert.new)

class FlowerFert < KettleAction
  def initialize
    super('Flower Fertilizer')
  end

  def start_pass(index)
    @first_pass = (index == 0)
  end

  def act_at(g)
    delay = 0.3
    w = KettleWindow.from_screen_click(g['x'], g['y'])
    unless @first_pass
      w.click_button('Take')
      sleep_sec delay
    end
    w.click_button('Flower Fert')
    sleep_sec delay
    w.click_button('Begin')
    sleep_sec delay
    AWindow.dismiss_all
    sleep_sec delay
  end
end
Action.add_action(FlowerFert.new)

class Salt < KettleAction
  def initialize
    super('Salt')
  end

  def act_at(g)
    w = KettleWindow.from_screen_click(g['x'], g['y'])
    w.click_button('Take')
    sleep_sec 0.1
    w.click_button('Salt')
    sleep_sec 0.1
    w.click_button('Begin')
    sleep_sec 0.1
    AWindow.dismiss_all
  end
end
Action.add_action(Salt.new)


class TakeFromKettles < KettleAction
  def initialize
    super('Take from kettles')
  end

  def act_at(g)
    w = KettleWindow.from_screen_click(g['x'], g['y'])
    w.click_button('Take')
    sleep_sec 0.3
    AWindow.dismiss_all
    sleep_sec 0.3
  end
end
Action.add_action(TakeFromKettles.new)


class KettleWindow < PinnableWindow

  def self.from_screen_click(x, y)
    pw = PinnableWindow.from_screen_click(x, y)
    return KettleWindow.new(pw.rect)
  end

  def initialize(rect)
    super
    yoff = 26
    @locs = {

      'take' => [50, 277],
      'begin' => [50, 277],
      'ignite' => [50, 277],
      'arsenic' => [50, 277],

      'potash' => [50, 175],
      'weed killer' => [160, 175],
      'grain fert' => [160, 202],
      'flower fert' => [50, 202],

      'acid' => [160, 277],
      'sulfur' => [50, 277],
      'salt' => [160, 253],
    }
    @locs.each_key {|k| @locs[k][1] -= yoff }
  end

  def click_button(which)
    xy = @locs[which.downcase]
    dialog_click(Point.new(xy[0], xy[1]), 'lc', 0.1)
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
      data_text_reader = TextReader.new(data_rect, self)
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
  def initialize(n = 'Potash')
    super(n)
  end

  def get_gadgets
    super << {:type => :combo, :label => 'Do what?', :name => 'action' ,
              :vals => ['Start and tend', 'Tend', 'Ignite and tend']
    }
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
    w = KettleWindow.from_screen_click(p['x'], p['y'])
    w.pin if pinned
    w
  end

  def make_this
    'potash'
  end

  def start_potash(p, ignite)
    w = pinned_kettle_window(p)
    unless ignite
      # Have to pause between these to let them update.
      w.click_button(make_this)
      sleep_sec(0.1)
      w.click_button('begin')
      sleep_sec(0.1)
    end
    w.click_button('ignite')
    HowMuch.max
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
      if task =~ /Start/ || task =~ /Ignite/
        grid.each_point do |p|
          start_potash(p, task =~ /Ignite/)
          done[p] = false
        end
      end

      # Tend until they're all done
      while done.values.include?(false)
        grid.each_point do |p|
          done[p] = stoke_kettle(p) unless done[p]
        end
        sleep_sec(3.0)
      end

      break unless task =~ /Start/

      # fill jugs
      Icons.refill
    end
  end

  # Look at the potash kettle at the point and decide what, if
  # anything, needs to be done. Return a true if the potash is
  # complete, false otherwise.
  def stoke_kettle(p)
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
      dismiss_all
    end
    return false
  end
  

end
Action.add_action(Potash.new)

# XXX Refactor this more cleanly. 
class Acid < Potash
  def initialize
    super('acid')
  end
  
  def make_this
    'acid'
  end
end
Action.add_action(Acid.new)
