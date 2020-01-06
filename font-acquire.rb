require 'robot/robot'
require 'action'

# This is just used to fill in the font files.
class FontAcquire < ARobot

  def run(str)
    f = Font.instance
    acquire(f, str)
  end

  def acquire(font, str_orig)
    str = str_orig.split(//).join(' ')
    send_string(str)
    send_string("\n")
    sleep 1
    tr = TextBlock.new([388, 947], 800, 17)
    
    g = tr.glyphs[0].dup
    chars = str_orig.split(//)
    if g.size != chars.size
      puts "Size mismatch for --@{str_orig}--"
      puts "glyphs: #{g.size}, chars: #{chars.size}"
      g.each {|x| puts x.to_s}
      return
    end
    # Add to the font.
    g.each {|g| font.add(g, chars.shift)}

    # Re-get it, and make sure we get the expected string back.
    got = TextBlock.new([388, 947], 800, 17).read_text
    if str_orig.strip != got.strip
      p str_orig
      p got
      puts "Mismatch: sent"
      puts str_orig
      puts '-- Got --'
      puts got
    end

  end
end





if __FILE__ == $0
  sleep 5
  FontAcquire.new.run('abcdefghijklmnopqrstuvwxyz')
  FontAcquire.new.run('ABCDEFGHIJKLMNOPQRSTUVWXYZ')
  FontAcquire.new.run('`1234567890-=')
  FontAcquire.new.run('~!@#$%^&*()_+')
  FontAcquire.new.run('[];\'\\,./')
  FontAcquire.new.run('{}:|<>?')
  
end
