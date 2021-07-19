require 'action'
require 'walker'

class MarbleDowse < Action
  CMD = 'CMD: '
  ACK = 'ACK: '
  SEPARATOR = 'Break, baby!'

  def initialize
    super('Marble prospect', 'Misc')
  end

  def setup(parent)
    gadgets = [
      {:type => :combo, :label => 'Doswer or Partner?', :name => 'dowser-or-partner', 
       :vals => ['Dowser', 'Partner']},
      {:type => :point, :label => 'Drag to Partner chat tab.', :name => 'partner-tab'},
      {:type => :point, :label => 'Drag to Main chat tab (dowser only).', :name => 'main-tab'},
      {:type => :point, :label => 'Drag to pinned Slate menu (dowser only).', :name => 'slate'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)

  end
    
  def act
    stash_point = point_from_hash(@vals, 'stash')
    @main_tab = point_from_hash(@vals, 'main-tab')
    @partner_tab = point_from_hash(@vals, 'partner-tab')
    @slate_win = PinnableWindow.new(point_from_hash(@vals, 'slate'))

    if @vals['dowser-or-partner'] == 'Dowser'
      dowser
    else
      partner
    end
  end


  # Vectors for direction partner should be relative to dowser, for
  # each stage.  Stage 0 is the diagonal, 30 coord separation. 
  def dirs_for_stage(stage)
    if (stage % 2) == 0
      return [[-1, -1], [1, -1], [1, 1], [-1, 1]]
    else
      return [[0, 1], [1, 0], [0, -1], [-1, 0]]
    end
  end

  # The delta x and/or y that partner should be from dowser at each
  # stage.  Stage 0 is the diagonal, 30 coord separation.
  def distance_for_stage(stage)
    d = [30, 16, 8, 4, 2, 1]
    return d[stage/2]
  end

  def dowser
    @chat_win = ChatWindow.find
    lclick_at(@partner_tab)
    stage0
    
  end

  def stage0
    dirs = dirs_for_stage(0)
    dist = dist(0)
    myloc = get_my_coords
    dirs.each do |dir|
      pcoords = [myloc[0] + dir[0] * dist, myloc[1] + dir[1] * dist ]
      send_cmd("goto #{pcoords}")
      wait_for_ack
      return true if prospect
    end
  end

  def get_my_coords
    ClockLocWindow.instance.coords.to_a
  end

  # Two slate shattered!
  # One slate shattered!
  # The bundle of slate remained intact.
  def prospect
    say_in_main SEPARATOR
    @slate_win.click_on('Prospect')
    sleep 1 until (line = last_chat_line).include? 'slate'
    return line.include 'Two slate '

  end

  def say_in_main(text)
    lclick_at(@main_tab)
    @chat_win.say(text)
  end

  def send_cmd(cmd)
    lclick_at(@partner_tab)
    send_text "#{CMD}#{cmd}"
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
      cmd  = wait_for_cmd
      if cmd
        response = eval cmd
        @chat_win.say "#{ACK}#{response}" 
      end
      sleep 1
    end
  end


  # Return the last chat line.
  def last_chat_line
    line = @chat_win.read_text.split("\n")[-1]
    return @chat_win.strip_timestamp(line)
  end


  # Wait for the last line in chat window to start with "ACK:" or
  # "CMD:"
  def wait_for_cmd_or_ack(cmd_or_ack)
    loop do
      last_line = last_chat_line
      return get_info(last_line, cmd_or_ack) if last_line.include?(cmd_or_ack)
      sleep 1
    end
  end
  def wait_for_cmd
    return wait_for_cmd_or_ack(CMD)
  end
  def wait_for_ack
    return wait_for_cmd_or_ack(ACK)
  end

  def saycoords
    "#{get_my_coords}"
  end

  # Parse the cmd/ack lines. 
  def get_info(line, prefix)
    index = line.index(prefix)
    return line.slice(index + prefix.size..-1) if index

    nil
  end
end

Action.add_action(MarbleDowse.new)
