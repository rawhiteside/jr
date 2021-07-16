require 'action'
require 'walker'

class MarbleDowse < Action
  def initialize
    super('Dowse for marble', 'Misc')
  end

  def setup(parent)
    gadgets = [
      {:type => :combo, :label => 'Doswer or Partner?', :name => 'dowser-or-partner', 
       :vals => ['Dowser', 'Partner']},
      {:type => :point, :label => 'Drag to Main chat tab.', :name => 'main-tab'},
      {:type => :point, :label => 'Drag to Partner chat tab.', :name => 'partner-tab'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)

  end
    
  def act
    stash_point = point_from_hash(@vals, 'stash')
    @main_tab = point_from_hash(@vals, 'main-tab')
    @partner_tab = point_from_hash(@vals, 'partner-tab')

    if @vals['dowser-or-partner'] == 'Dowser'
      dowser
    else
      partner
    end
  end

  # Partner just listens for commands. 
  # Expected commands:
  # CMD: goto [x, y] # Walk to provided location. 
  # CMD: say_coords # Tell current coords.  ACK: [100, -200]
  def partner
    @chat_win = ChatWindow.find
    lclick_at(@partner_tab)
    sleep 1
    loop do
      last_line = @chat_win.read_text.split("\n")[-1]
      cmd = get_cmd(last_line)
      if cmd
        eval cmd
        @chat_win.say 'ACK: ' if cmd.include?('goto')
      end
      sleep 1
    end
  end

  def saycoords
    @chat_win.say("ACK: #{ClockLocWindow.instance.coords.to_a}")
  end

  # Parse the cmd/ack lines. 
  def get_ack(line)
    get_info(line, 'ACK: ')
  end
  def get_cmd(line)
    get_info(line, 'CMD: ')
  end
  def get_info(line, prefix)
    index = line.index(prefix)
    return line.slice(index + prefix.size..-1) if index

    nil
  end
end

Action.add_action(MarbleDowse.new)
