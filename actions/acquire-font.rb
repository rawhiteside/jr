require 'action'
require 'window'
require 'actions/kettles'

import org.foa.text.AFont
import org.foa.text.InkSpots

class AcquireFont < Action
  def initialize
    super('Acquire font', 'Test/Dev')
  end

  CHAT_WINDOW = 'Chat Window'
  CLOCK_LOC = 'ClockLoc Window'
  SKILLS = 'Skills Window'
  INVENTORY = 'Inventory Window'
  PINNABLE = 'Pinnable Window'
  DUMP_GLYPHS = 'Dump glyphs to stdout'
  def setup(parent)
    gadgets = [
      {:type => :combo, :label => 'Which window?', :name => 'which',
       :vals => [PINNABLE, CHAT_WINDOW, CLOCK_LOC, SKILLS, INVENTORY, DUMP_GLYPHS],
      },
      {:type => :point, :label => 'Drag to Pinnable if selected', :name => 'xy'},
      
    ]
    @vals = UserIO.prompt(parent, nil, action_name, gadgets)
  end
  
  def make_text_for_glyph(g)
    text = ''
    g.rows.each do |row|
      text << row
      text << "\n"
    end

    text
  end

  def handle_glyph(line, g)
    glyph_text = make_text_for_glyph(g)
    comps = [
      {:type => :text, :name => 'answer', :label => 'What is that?'},
      {:type => :label, :label => line},
      {:type => :big_text, :editable => false, :label => 'Glyph',
	:name => 'glyph', :value => glyph_text, :rows => 20, :cols => 50},
    ]
    vals = UserIO.prompt(nil, nil, 'What is this glyph?', comps)
    return unless vals
    chars = vals['answer']
    @window.getFontMap().add(g.rows, chars) unless chars == ''
  end

  def get_target_window
    case @vals['which']
    when CHAT_WINDOW
      ChatWindow.find
    when CLOCK_LOC
      ClockLocWindow.instance
    when SKILLS
      SkillsWindow.new
    when INVENTORY
      InventoryWindow.find
    when PINNABLE
      PinnableWindow.from_point(point_from_hash(@vals, 'xy'))
    else
      nil
    end
  end

  def process_line(glyph_line, glyphs)
    glyphs.each do |g|
      if g.to_s.include?('?')
	line = ''
	glyphs.each {|gl| line << gl.to_s}
	handle_glyph(line, g)
      end
    end
  end

  def process_text_reader(tr)
    text_lines = tr.read_text(false).split("\n")
    text_lines.size.times do |i|
      process_line(text_lines[i], tr.glyphs[i])
    end
    puts tr.read_text
  end

  def dump_font(map)

    # Value is an arraylist of strings
    map.each do |k,v|
      puts "------------#{v} =>"
      strs = k.to_a
      strs.each do |str|
        puts str.to_s
      end
    end
  end
  


  def act
    if @vals['which'] == DUMP_GLYPHS
      dump_font(AFont.instance.getFontMap)
      return
    else
      @window = get_target_window
      process_text_reader(@window.text_reader)
    end
  end
end

Action.add_action(AcquireFont.new)
