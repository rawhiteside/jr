require 'action'
require 'window'
require 'actions/kettles'

import org.foa.text.AFont
import org.foa.text.InkSpots
import org.foa.window.LegacyTextHelper
import org.foa.window.PinnableTextHelper
import org.foa.window.InventoryTextHelper

class SplitLongGlyphs < Action
  def initialize
    super('Split long glyphs', 'Test/Dev')
  end

  def setup(parent)
    true
  end

  def act
    afont = AFont.instance("data/font.yaml")
    font_map = afont.font_map
    font_map.keys.each do |key|
      v = font_map[key]
      break unless ask_about_glyph(afont, key, v) if v.length > 1
    end
  end

  def ask_about_glyph(afont, glyph, chars)

    comps = [
      {:type => :text, :name => 'widths', :label => 'Give the width of each letter, comma separated'},
      {:type => :text, :name => 'abort', :label => 'Put something here to abort.'},
      {:type => :label, :label => "Text is: #{chars}"},
      {:type => :big_text, :editable => false, :label => 'Glyph',
	:name => 'glyph', :value => glyph.join("\n"), :rows => 20, :cols => 100},
    ]
    vals = UserIO.prompt(nil, nil, 'Split this?', comps)
    return true unless vals
    return false if vals['abort'].length > 0

    answer = vals['widths']
    return true unless answer
    return true if answer.delete(' ').length == 0
    widths  = []
    answer.delete(' ').split(',').each {|a| widths << a.to_i}
    if widths.length != chars.length
      UserIO.error("Got #{widths.length} widths for #{chars.length} characters.")
      return
    end
    total_width = 0
    widths.each {|w| total_width += w}
    if total_width != glyph[0].length
      UserIO.error("Total width #{total_width}, bus glyph width #{glyph[0].length}")
      return true
    end
    
    add_split_glyphs(afont, glyph, widths, chars)

    return true
  end

  def add_split_glyphs(afont, glyph, widths, str)

    save_glyph = glyph.to_a

    widths.length.times do |i|
      front = []
      back = []
      glyph.each do |line|
        front << line[0, widths[i]]
        back << line[widths[i], line.length - widths[i]]
      end
      glyph = back
      trim_height(front)
      add_it(afont, front, str[i])

    end
    afont.remove(save_glyph)
  end

  def trim_height(lines)
    # Trim the top
    lines.shift while lines[0].strip.length == 0
    # and the bottom
    lines.pop while lines[-1].strip.length == 0
  end

  def add_it(afont, glyph, letter)
    puts "Adding this: "
    puts glyph.join("\n")
    afont.add(glyph, letter)
  end

end
Action.add_action(SplitLongGlyphs.new)

class AcquireFont < Action
  def initialize
    super('Acquire font', 'Test/Dev')
  end

  CHAT_WINDOW = 'Chat Window'
  CLOCK_LOC = 'ClockLoc Window'
  SKILLS = 'Skills Window'
  INVENTORY = 'Inventory Window'
  PINNABLE = 'Pinnable Window'
  ERR_LOG = 'Err log directory'
  DUMP_GLYPHS = 'Dump glyphs to stdout'
  def setup(parent)
    gadgets = [
      {:type => :combo, :label => 'Which window?', :name => 'which',
       :vals => [PINNABLE, CHAT_WINDOW, CLOCK_LOC, SKILLS, INVENTORY, DUMP_GLYPHS, ERR_LOG],
      },
      {:type => :point, :label => 'Drag to Pinnable if selected', :name => 'xy'},
      
    ]
    @vals = UserIO.prompt(parent, name, action_name, gadgets)
  end
  
  def make_text_for_glyph(g)
    text = ''
    g.rows.each do |row|
      text << row
      text << "\n"
    end

    text
  end

  def handle_glyph(line, g, font_map)
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
    font_map.add(g.rows, chars) unless chars == ''
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

  def process_line(glyph_line, glyphs, font_map)
    glyphs.each do |g|
      if g.to_s.include?(AFont.unknown_glyph)
	line = ''
	glyphs.each {|gl| line << gl.to_s}
	handle_glyph(line, g, font_map)
      end
    end
  end

  def process_text_reader(tr)
    text_lines = tr.read_text(false).split("\n")
    text_lines.size.times do |i|
      process_line(text_lines[i], tr.glyphs[i], tr.text_helper.font_map)
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
  
  def text_helper_for(img_name)
    if img_name.include?('pinnable')
      return PinnableTextHelper.new
    elsif img_name.include?('legacy')
      return LegacyTextHelper.new
    elsif img_name.include?('inventory')
      return InventoryTextHelper.new
    else
      puts "unknown type of screenshot image"
    end
    nil
  end

  def process_image(img_name)
    puts "---File name: #{img_name}"
    pb = PixelBlock.load_image(img_name)
    helper = text_helper_for(img_name)
    tr = TextReader.new(pb, helper)
    text = tr.read_text
    return unless text.include?(AFont.unknown_glyph)
    puts "---- Problem image text:"
    puts text
    UserIO.show_image(pb, img_name)
    process_text_reader(tr)
  end

  def process_dir
    png_files = File.join('screen-shots', '*.png')
    Dir.glob(png_files).each { |img| process_image(img) }
  end

  def act
    if @vals['which'] == DUMP_GLYPHS
      dump_font(AFont.instance.getFontMap)
      return
    elsif @vals['which'] == ERR_LOG
      process_dir
    else
      process_text_reader(get_target_window.text_reader)
    end
  end
end

Action.add_action(AcquireFont.new)
