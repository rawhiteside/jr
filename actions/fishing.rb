require 'action'
require 'window'

class Fishing < Action
  def initialize(n = "Fish")
    super(n, 'Gather')
  end

  def setup(parent)
    gadgets = [
      {:type => :text, :label => 'Lure name (otherwise cycle)', :name => 'lure'},
      {:type => :point, :label => 'Drag to pinned lure window', :name => 'lure-win'},
    ]
    @uvals = UserIO.prompt(parent, name, action_name, gadgets)
  end

  def act
    @specified_lure = @uvals['lure']
    p @uvals
    lure_win = PinnableWindow.from_point(point_from_hash(@uvals, 'lure-win'))
    chat_win = ChatWindow.find
    
    lures = lure_list(lure_win)
    puts lures
    loop do
      select_lure(lure_win, lures)
      send_string('9')
      wait_for_fishing_done(chat_win)
    end
  end

  FISHING_DELAY = 17
  def wait_for_fishing_done(chat_win)
    orig = chat_win.read_text_no_timestamp
    # If more than 17 seconds, but proceed anyway. 
    FISHING_DELAY.times do
      sleep 1
      check_for_pause
      current = chat_win.read_text_no_timestamp
      last_line = current.split("\n")[-1]
      if last_line && last_line.include?('already fishing!')
        sleep FISHING_DELAY
        return
      end
      if last_line && last_line.include?("The Fishing Lure")
        orig = current
      end
 
      if orig != current
        if last_line.match(/Caught/)
          puts last_line
          puts @current_lure
        end
        return
      end
    end
  end

  def select_lure(lure_win, lures)
    lure_win.refresh
    return if select_specified_lure(lure_win, lures)
    select_cycled_lure(lure_win, lures)
  end

  def select_specified_lure(lure_win, lures)
    return false if @specified_lure.nil? || @specified_lure.strip == ''
    lure_win.click_on(@specified_lure + '/Desel')     
    if lure_win.click_on(@specified_lure + '/Sel')
      @current_lure = @specified_lure
      return true
    else
      return nil
    end
  end
  
  def select_cycled_lure(lure_win, lures)
    lures.size.times do |i|
      l = lures[0]
      clicked = lure_win.click_on(l)
      lures.rotate!
      if clicked
        @current_lure = l
        return
      end
      sleep 1
    end
  end

  def lure_list(win)
    lines = win.read_text.split("\n")
    lines = lines.collect do |l|
      paren = l.index('(')
      (paren.nil? ? l : l[0,paren]).strip
    end

    lines.uniq
  end

end
Action.add_action(Fishing.new)
