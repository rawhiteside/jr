require 'java'
require 'buildmenu'
require 'action'
require 'robot'

import org.foa.PixelBlock

import org.foa.window.WindowGeom
import org.foa.window.AWindow
import org.foa.window.PinnableWindow
import org.foa.window.ClockLocWindow

import java.awt.Point
import java.awt.Rectangle
import java.awt.Insets

# Adds a factory method that's useful in Ruby.
class Window < AWindow
  def initialize(rect = nil)
    super(rect)
  end

  # Return a Window from a point in the dialog
  def self.from_point(pt)
    rect = WindowGeom.rect_from_point(pt)
    return nil unless rect
    self.new(rect)
  end
end

class HowMuch < Window

  # Answer the "How Much" / "How Many" popup
  # Arg can either a number, or one of [:max, :ok, :cancel]
  def initialize(quant)
    super(Rectangle.new(0,0,0,0))
    with_robot_lock do
      @win = nil
      sleep_sec(0.1)
      5.times do
        @win = HowMuch.find_win
	break if @win 
	sleep_sec 0.1
      end

      raise(Exception.new("The How Much dialg didn't appear")) unless @win

      rect = @win.rect
      @win.dialog_click(Point.new(110, rect.height - 30)) if quant == :max
      @win.dialog_click(Point.new(170, rect.height - 45)) if quant == :ok
      if quant.kind_of?(Numeric)
        robot = ARobot.sharedInstance
	robot.send_string(quant.to_i.to_s)
	@win.dialog_click(Point.new(170, rect.height - 45))
      end
      # Wait until it's gone.
      5.times do 
        got = HowMuch.find_win
        break unless got
	sleep_sec 0.1
      end

    end
    
    sleep_sec 0.1
  end

  # Click on the cancel button.
  def self.cancel(w)
    puts 'Cancelling a HowMuch'
    rect = w.rect
    w.dialog_click(Point.new(170, rect.height - 20))
  end

  def self.cancel_if_present
    w = find_win
    cancel(w) if w
  end

  def self.find_win
    dim = ARobot.sharedInstance.screen_size
    wid, height = dim.width, dim.height
    win = Window.from_point(Point.new(wid/2, height/2))
    if win && win.read_text =~ /(H|h)ow (much|many)/
      return win
    else
      return nil
    end

  end
end


# A window with a message that pops up in the middle of the screen
class PopupWindow < Window
  def self.find
    dim = ARobot.sharedInstance.screen_size
    wid, height = dim.width, dim.height
    PopupWindow.from_point(Point.new(wid/2, height/2))
  end

  def textInsets
    # { :right => 32, :left => 14, :top => 14, :bottom => 5 }
    Insets.new(14, 14, 5, 32)
  end

  # try to dismiss the popup thing.  Click on the last glyph from the
  # text.  This is hopefully the "OK" button, which the text can't
  # handle.
  def dismiss

    # This is an array glyphs[letters][lines]
    glyphs = text_reader.glyphs
    return if glyphs.size == 0

    # last glyph on the last line.
    last_line = glyphs[glyphs.size - 1]
    glyph = last_line[last_line.size - 1]
    x = glyph.origin[0] + glyph.width / 2;
    y = glyph.origin[1] + glyph.height / 2;
    rclick_at(x, y)
  end
  
end

class FixedWindow < Window

  # Search from provided +xy+ point, in direction specified by +step+.
  # *step+ is an array with increment vals for x and y, as in [0, -1]
  # to search up
  # 
  # For these windows, start at a known point on the background.  We
  # don't search for the multicolor borders here.
  # Return x, y
  def find_edge(pb, x, y, step)
    loop do
      c = pb.color_from_screen(x, y)
      # We stop on a darker pixel
      return x,y if c.get_red < 200

      x += step[0]
      y += step[1]
      return -1, -1 unless x > 0
    end
  end
end

# Base class for ChatHistory and for ChatLineWindow.
class ChatWindow < FixedWindow

  def find_left_edge(x, y)
    pb = PixelBlock.new(Rectangle.new(0, y, x+1, 1))
    xo, yo = find_edge(pb, x, y, [-1, 0])
    return xo
  end

  def find_right_edge(x, y)
    swidth = screen_size.width
    pb = PixelBlock.new(Rectangle.new(x, y, swidth - x, 1))
    xo, yo = find_edge(pb, x, y, [1, 0])
    return xo
  end
  
  def find_top_edge(x, y)
    pb = PixelBlock.new(Rectangle.new(x, 0, 1, y+1))
    xo, yo = find_edge(pb, x, y, [0, -1])
    return yo
  end

  def textInsets
    # { :right => 4, :left => 4, :top => 3, :bottom => 0 }
    Insets.new(3, 4, 0, 4)
  end

  def textReader
    flushTextReader
    super
  end
  
end

class ChatLineWindow < ChatWindow
  def initialize
    compute_rect
  end

  # Minimize the chat.  If there's some typing in there,
  # wait for it to be sent before minimizing.
  def minimize(if_min = true)
    text = read_text
    if text =~ /Press Enter to Chat/
      return if if_min
    else
      return unless if_min
    end

    if if_min
      # In case I'm currently typing something to a chat window, wait
      # for the chatline to become empty.
      wait_for_empty_chatline
      send_vk(VK_RETURN) unless read_text =~ /Press Enter to Chat/
    else
      # Need to un-minimize.
      send_vk(VK_RETURN)
    end
    
  end

  def wait_for_empty_chatline
    loop do
      break if read_text == ''
      sleep_sec 1
    end
  end

  def compute_rect
    dim = screen_size
    s_width, s_height = dim.width, dim.height
    y_bottom = s_height - 40
    x_right = s_width - 29
    # Need to search to find the top and left edges.
    x_left = find_left_edge(x_right, y_bottom)
    y_top = s_height - 56
    set_rect(Rectangle.new(x_left + 1, y_top,
			   x_right - x_left,
			   y_bottom - y_top))
  end
end

class SkillsWindow < ChatWindow
  def initialize
    super(Rectangle.new(0,0,0,0))
    set_rect(compute_rect)
  end

  def textInsets
    # { :right => 3, :left => 0, :top => 0, :bottom => 0 }
    Insets.new(0, 0, 0, 3)
  end

  def compute_rect
    s_height = screen_size.height
    y_bottom = s_height - 50
    x_left = 10
    y_top = find_top_edge(x_left, y_bottom)
    y_top += 1

    # Don't search along the top:  no border to stop the search.
    # Instead, search below the "weight/bulk" line.
    x_right = find_right_edge(x_left, y_top + 25)
    
    Rectangle.new(x_left, y_top,
		  x_right - x_left,
		  y_bottom - y_top)
  end
  
end

class ChatHistoryWindow < ChatWindow

  def initialize
    super()
    compute_rect
  end

  def compute_rect
    dim  = screen_size
    s_width, s_height = dim.width, dim.height
    y_bottom = s_height - 60
    x_right = s_width - 27
    # Need to search to find the top and left edges.
    x_left = find_left_edge(x_right, y_bottom)
    y_top = find_top_edge(x_right, y_bottom)
    set_rect(Rectangle.new(x_left, y_top,
			   x_right - x_left,
			   y_bottom - y_top))
  end
  
end



# This class does the tiling, computing coordinates at which
# to place dialogs.
class Tiler < ARobot
  # Overlap must not be 0.5 or greater, or 
  # pinnables will be invisible!
  def initialize(x, y, ovlp_fraction = 0.0)
    super()
    @xtile = [x,2].max
    @ytile = y
    @ymax = 0
    @y_off = 0
    @ovlp = ovlp_fraction
    @min_width = 0
    @min_height = 0
  end

  # Set a minimuim width to use when tiling.  Windows can change width. 
  def min_width=(min_width)
    @min_width = min_width
  end
  def min_height=(min_height)
    @min_height = min_height
  end

  # Normally, next row starts just below the previous.
  # Set this for an additional offset, in addition to the above.
  def y_offset=(y_off)
    @y_off = y_off
  end

  # There is a stack of windows a [x, y].  We'll tile them, and return
  # the window list.
  def tile_stack(x, y, delay = 0)
    point = Point.new(x, y)
    windows = []
    loop do
      w = PinnableWindow.from_point(point)
      break unless w
      windows << w
      tile(w, delay)

    end
    windows
  end

  def tile(pinnable, delay = 0)
    s_width = screen_size.width

    pinnable.default_refresh_loc = 'tc' if @ovlp > 0.0
    width = [pinnable.rect.width, @min_width].max

    if (@xtile + width) >= s_width
      @xtile = 2
      @ytile = (@ymax + 1 + @y_off)
      @ymax = 0
    end

    # Grab the window height now, before we move it.  The window may
    # shrink when we move it.  If so, track the max y using the max of
    # the two heights.
    prev_height = pinnable.rect.height
    with_robot_lock do
      pinnable.drag_to(Point.new(@xtile, @ytile))

      curr_height = pinnable.rect.height
      use_height = [prev_height, curr_height, @min_height].max
      @xtile += ((1.0 - @ovlp) * width ).to_i
      @ymax = [@ymax, @ytile + use_height].max
    end

    pinnable
  end
end
