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
    delay = 0.01
    w = KettleWindow.from_screen_click(g['x'], g['y'])
    unless @first_pass
      w.click_word('Take')
      sleep delay
    end
    w.click_word('Grain Fert' )
    sleep delay
    w.click_word('Begin')
    sleep delay
    AWindow.dismiss_all
    sleep delay
  end
end
Action.add_action(Fert.new)


class KettleNoStoke < KettleAction
  def initialize
    super('Kettle no-stoke')
  end

  def get_gadgets
    gadgets = super
    gadgets << 
    {
      :type => :combo, :label => 'Make what?', :name => 'what' ,
      :vals => ['Salt', 'Grain Fert', 'Flower Fert']
    }

    gadgets
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
    w.click_word(@user_vals['what'])
    sleep delay
    w.click_word('Begin')
    sleep delay
    AWindow.dismiss_all
    sleep delay
  end
end
Action.add_action(KettleNoStoke.new)



class TakeFromKettles < KettleAction
  def initialize
    super('Kettles take')
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

  # The useful numbers in the data area.
  # vals[:water] and vals[:wood]
  def kettle_data
    vals = {}
    text = read_text
    match = Regexp.new('Wood: ([0-9]+)').match(text)
    vals[:wood] = match[1].to_i if match
    match = Regexp.new('Water: ([0-9]+)').match(text)
    vals[:water] = match[1].to_i if match
    vals[:done] = (text =~ /The recipe is complete/)
    
    vals
  end

  # Waiting for the window to update itself.
  def click_word(word)
    5.times do |i|
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

class KettleStoke < KettleAction
  def initialize(n = 'Kettles stoke')
    super(n)
  end

  def get_gadgets
    gadgets = super
    gadgets << 
    {
      :type => :combo, :label => 'Make what?', :name => 'what' ,
      :vals => ['Sulfur', 'Potash', 'Acid']
    }
    gadgets <<
      {
      :type => :combo, :label => 'Do what?', :name => 'action' ,
      :vals => ['Start and tend', 'Tend', 'Ignite and tend']
      }
    gadgets
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
    @user_vals['what']
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
      Icons.refill if make_this == 'Potash'
    end
  end

  # Look at the potash kettle at the point and decide what, if
  # anything, needs to be done. Return a true if the potash is
  # complete, false otherwise.
  def stoke_kettle(p)
    w = kettle_window(p)
    v = {}
    5.times do
      v = w.kettle_data
      break if (v[:wood] && v[:water]) || v[:done]
      sleep (0.1)
    end
    
    unless (v[:wood] && v[:water]) || v[:done]
      puts "Didn't read kettle: "
      puts w.read_text
      puts v
      puts w.kettle_data
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
Action.add_action(KettleStoke.new)
