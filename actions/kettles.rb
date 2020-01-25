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
  
  def act_at(ginfo)
    delay = 0.01
    unless @first_pass
      w.click_word('Take')
      sleep delay
    end
    w = KettleWindow.from_screen_click(ginfo['x'], ginfo['y'])
    w.click_word('Grain Fert' )
    sleep delay
    w.click_word('Begin')
    sleep delay
    AWindow.dismiss_all
    sleep delay
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

  def end_pass(index)
    fill_jugs
  end

  def act_at(g)
    delay = 0.3
    w = KettleWindow.from_screen_click(g['x'], g['y'])
    unless @first_pass
      w.click_word('Take')
      sleep delay
    end
    w.click_word('Flower Fert')
    sleep delay
    w.click_word('Begin')
    sleep delay
    AWindow.dismiss_all
    sleep delay
  end
end
Action.add_action(FlowerFert.new)

class Salt < KettleAction
  def initialize
    super('Salt')
  end

  def act_at(g)
    w = KettleWindow.from_screen_click(g['x'], g['y'])
    w.click_word('Take')
    sleep 0.1
    w.click_word('Salt')
    sleep 0.1
    w.click_word('Begin')
    sleep 0.1
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
    w.click_word('Take')
    sleep 0.1
    AWindow.dismiss_all
  end
end
Action.add_action(TakeFromKettles.new)


class KettleWindow < PinnableWindow
  def self.from_screen_click(x, y)
    pw = PinnableWindow.from_screen_click(x, y)
    return KettleWindow.new(pw.rect)
  end

  def click_word(word)
    5.times do
      p = super
      if p.nil?
        sleep 0.1
      else
        return p
      end
    end
    return nil
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
    #puts "Window text"
    #puts w.read_text
    text = w.read_text
    #puts "Data text"
    #puts text
    match = Regexp.new('Wood: ([0-9]+)').match(text)
    vals[:wood] = match[1].to_i if match
    match = Regexp.new('Water: ([0-9]+)').match(text)
    vals[:water] = match[1].to_i if match
    vals[:done] = (text =~ /The recipe is complete/)
    
    vals
  end

  def kettle_window(p)
    return KettleWindow.from_screen_click(p['x'], p['y'])
  end

  def pinned_kettle_window(p)
    w = kettle_window(p)
    w.pin
    return w
  end

  def make_this
    'Potash'
  end

  def start_potash(p, ignite)
    w = pinned_kettle_window(p)
    unless ignite
      # Have to pause between these to let them update.
      sleep 0.1
      w.click_word(make_this)
      sleep 0.1
      w.click_word('Begin')
      sleep 0.1
    end
    w.click_word('Ignite')
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
        sleep(3.0)
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
    w = kettle_window(p)
    v = {}
    5.times do
      v = kettle_data(w)
      break if (v[:wood] && v[:water]) || v[:done]
      sleep (0.1)
    end
    
    unless (v[:wood] && v[:water]) || v[:done]
      puts "Didn't read kettle: "
      puts w.read_text
      puts v
      puts kettle_data(w)
      puts "----"
      return true
    end

    if v[:done]
      w.click_word('Take')
      dismiss_all
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
