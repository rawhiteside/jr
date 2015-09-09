require 'action'
require 'window'
require 'actions/kettles'

import org.foa.text.AFont

class AcquireFont < Action
  def initialize
    super('Acquire font', 'Test/Dev')
  end

  def get_window(parent)
    comps = [
      {:type => :point, :label => 'Drag to window', :name => 'w'}
    ]
    vals = UserIO.prompt(parent, nil, 'Window to read', comps)
    return nil unless vals

    dim = screen_size
    s_width, s_height = dim.width, dim.height
    
    x = vals['w.x'].to_i
    y = vals['w.y'].to_i
    pt = point_from_hash(vals, 'w')
    p [x, y]
    if x > (s_width - 100) && y > (s_height - 200) && y < (s_height - 62)
      puts 'Chat History'
      return ChatHistoryWindow.new
    elsif x > 1160 && y > 962
      puts 'Chat Line'
      return ChatLineWindow.new
    elsif  x < 60 && y > 940
      puts 'Items/Skills'
      return SkillsWindow.new
    elsif  y < 64 && x > 830 && x  < 1000
      puts 'ClockLoc'
      return ClockLocWindow.instance
    else
      puts 'Pinnable'
      return PinnableWindow.from_point(pt)
    end
  end

  def make_text_for_glyph(g)
    text = ''
    g.rows.each do |row|
      row.split('').each do |c|
	if c == '0'
	  text << '@'
	else
	  text << ' . '
	end
      end
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
	:name => 'glyph', :value => glyph_text, },
    ]
    vals = UserIO.prompt(nil, nil, 'What is this glyph?', comps)
    return unless vals
    chars = vals['answer']
    AFont.instance.add(g.rows, chars)
  end

  def process_line(glyph_line, glyphs)
    glyphs.each do |g|
      if g.to_s == '?'
	line = ''
	glyphs.each {|gl| line << gl.to_s}
	handle_glyph(line, g)
      end
    end
  end

  def process_text_reader(tr)
    text_lines = tr.read_text.split("\n")
    text_lines.size.times do |i|
      process_line(text_lines[i], tr.glyphs[i])
    end
    puts tr.read_text
  end

  def setup(comp)
    @window = get_window(comp)
  end

  def act
    process_text_reader(@window.text_reader)
    if @window.respond_to?(:data_text_reader)
      process_text_reader(@window.data_text_reader)
    end
  end
end

Action.add_action(AcquireFont.new)
