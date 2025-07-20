require 'action'
require 'image_utils'

class Chariot < Action
  @@chariot_stops = [
    "Al-Kharijah (Western Desert)",
    "Avaris (Red Sea)",
    "Dukki Gel (Kerma)",
    "Kahun (Lahun)",
    "Koptos (Upper Egypt)",
    "Meroe (Blue Nile)",
    "Sharuhen (Bernike)",
    "Sheba (Axum)",
    "Taba (South Sinai)",
    "Tanis (Meshwesh Delta)",
    "Tell Ed Daba (East Sinai)",
    "Valley of the Queens (West Kush)",
  ]
  def initialize(name = 'Chariot ride')
    super(name, 'Misc')
  end

  def setup(parent)
    gadgets = [
      {:type => :combo, :label => "Destination", :name => 'dest',
       :vals => @@chariot_stops},
    ]
    @vals = UserIO.prompt(parent, name, 'Destination', gadgets)
  end

  def act
    puts @vals
    # Look around for a chariot to click on.
    dest = "Destination: #{@vals['dest']}"
    rm = RangeMatch.new
    pt = rm.click_point('chariot')
    puts pt.to_s
    win = PinnableWindow.from_screen_click(pt)
    puts win.read_text
    pt = win.coords_for_line(dest)
    puts pt.to_s
    travel_win = PinnableWindow.from_screen_click(pt)
    loop do
      return if travel_win.click_on("Travel now for free")
      return if travel_win.click_on("Travel now on house")
      sleep 60
      travel_win.refresh
    end
    PinnableWindow.dismiss_all
  end

  # Returns hash of :is_free, :wait_minutes, 
  def chariot_window_vals(win)
    text = win.read_text
    match = Regexp.new('Travel will be free in +([0-9 ]+)minute').match(text)
    vals = {:wait_minutes => match[1].tr(' ','').to_i,}
    vals[:is_free] = text.include?('Travel now for free')
  end


end
Action.add_action(Chariot.new)
