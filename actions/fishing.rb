require 'action'
require 'window'

class Fishing < Action
  def initialize(n = "Fish")
    super(n, 'Gather')
  end

  def setup(parent)
    gadgets = [
      # {:type => :text, :label => 'Lure name (otherwise cycle)', :name => 'lure'}
      {:type => :point, :label => 'Drag to pinned lure window', :name => 'lure-win'},
    ]
    @uvals = UserIO.prompt(parent, name, action_name, gadgets)
  end

  def act
    lure_win = PinnableWindow.from_point(point_from_hash(@uvals, 'lure-win'))
    chat_win = ChatWindow.find
    
    lures = lure_list(lure_win)
    loop do
      select_lure(lure_win, lures)
      send_string('9')
      wait_for_fishing_done(chat_win)
    end
  end

  def wait_for_fishing_done(chat_win)
    orig = chat_win.read_text_no_timestamp
    loop do
      sleep 1
      current = chat_win.read_text_no_timestamp
      last_line = current.split("\n")[-1]
      if last_line.include?('already fishing!')
        sleep 17
        next
      end
      if last_line.include?("The Fishing Lure")
        orig = current
      end
      return if orig != current
    end
  end

  def select_lure(lure_win, lures)
    lure_win.refresh
    lures.size.times do |i|
      # XXX Font error here.  FIx it later, Bob.
      clicked = lure_win.click_on(lures[0] + '/Select') || lure_win.click_on(lures[0] + '/SeleCt')
      lures.rotate!
      return if clicked
      sleep 1
    end
  end

  def lure_list(win)
    lines = win.read_text.split("\n")
    lines.shift
    lines = lines.collect do |l|
      paren = l.index('(')
      (paren.nil? ? l : l[0,paren]).strip
    end

    lines.uniq
  end

end
Action.add_action(Fishing.new)
