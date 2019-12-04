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
  def initialize(rect = Rectangle.new(0, 0, 0, 0))
    super(rect)
  end

  # Return a Window from a point in the dialog
  def self.from_point(pt)
    rect = WindowGeom.rect_from_point(pt)
    return nil unless rect
    self.new(rect)
  end
end


class ChatWindow < Window
  def initialize(rect = Rectangle.new(0, 0, 0, 0))
    super(rect)
  end

  def textInsets
    # top, left, bottom, right
    Insets.new(10, 10, 10, 35)
  end
end

# This class is poorly designed.  Slowly improving.
class HowMuch < Window

  # Answer the "How Much" / "How Many" popup
  # Arg can either a number, or one of [:max, :ok, :cancel]
  def initialize
    super(Rectangle.new(0,0,0,0))
  end

  # Find the HowMuch window, waiting for .5 sec if necessary.  Returns
  # the window, or nil.
  private
  def self.wait_for_win
    win = nil
    ARobot.shared_instance.sleep_sec(0.1)
    5.times do
      win = HowMuch.find_win
      break if win 
      ARobot.shared_instance.sleep_sec 0.1
    end

    win
  end

  def self.wait_till_gone
   # Wait until it's gone.
    5.times do 
      got = HowMuch.find_win
      break unless got
      ARobot.shared_instance.sleep_sec(0.1)
    end
  end
  # Click on the Max button.  Returns +true+ on success, or +nil+ if
  # the window doesn't appear.
  public
  def self.max
    win = wait_for_win
    return nil unless win
    win.dialog_click(Point.new(110, win.rect.height - 30), 'lc', 0.1)
    wait_till_gone

    true
  end

  # Send the provided amount  Returns +true+ on success, or +nil+ if
  # the window doesn't appear.
  public
  def self.amount(amt)
    win = wait_for_win
    return nil unless win
    robot = ARobot.shared_instance
    robot.send_string(amt.to_i.to_s, 0.05)
    ARobot.shared_instance.sleep_sec(0.1)
    win.dialog_click(Point.new(170, win.rect.height - 45))
    wait_till_gone
    
    true
  end
  
  # Click on the cancel button.
  private
  def self.cancel(w)
    w.dialog_click(Point.new(170, w.rect.height - 20))
  end

  
  # Cancel the dialog if it is found. 
  public
  def self.cancel_if_present
    w = find_win
    cancel(w) if w
  end

  private
  def self.find_win
    dim = ARobot.sharedInstance.screen_size
    wid, height = dim.width, dim.height
    win = Window.from_point(Point.new(wid/2, height/2))
    if win && win.read_text =~ /(much|many)/
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

  # Dismiss one if it's there. 
  def self.dismiss
    w = self.find
    w.dismiss if w
  end

  def textInsets
    # { :right => 32, :left => 14, :top => 14, :bottom => 5 }
    Insets.new(14, 14, 5, 32)
  end

  # try to dismiss the popup thing.  Click on the last glyph from the
  # text.  This is hopefully the "OK" button, which the text can't
  # handle.
  def dismiss

    # This is an array glyphs[lines][letters]
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

# Confirmation window: Yes/No answer
class ConfirmationWindow < PopupWindow
  def self.yes
    w = self.find
    w.dialog_click(Point.new(115, 151 - 23)) if w

    return w
  end

  def self.no
    w = self.find
    w.click_on('No') if w

    return w
  end
end



class DarkWindow < AWindow
  def initialize(rect)
    super(rect)
  end
  
  def textInsets
    # { :right => 3, :left => 0, :top => 0, :bottom => 0 }
    Insets.new(4, 4, 4, 4)
  end

  def isInk(color)
    !background?(color)
  end

  def background?(color)
    color.red < 50 &&
    color.green < 75  &&
    color.blue < 75 
  end
end


# what a hack.  I got tired of trying to solve the transparency
# problem in the face of time-of-day lighting changes.
# 
# So, you've gotta stretch the friends list down.  Put the skills
# window atop this near the bottom.  Both of these have to he on the
# left near the bottom.  Borders of the friends list have to be all
# visible.
class SkillsWindow < DarkWindow

  def initialize
    super(Rectangle.new(0, 0, 0, 0))
    dim = screen_size
    rect = WindowGeom.rect_from_point(Point.new(70, dim.height - 150))
    set_rect(rect)
  end

end

class InventoryWindow < DarkWindow
  def initialize(rect)
    super(rect)
  end

  def self.from_point(pt)
    rect = WindowGeom.rect_from_point(pt)
    return InventoryWindow.new(rect)
  end
end



# Manages a pair of window piles on the screen.
#
# Lifecycle:
# Create a Plier, then use +pile(w)+ to add +w+ to the "current" pile.
# These will be piled atop each other, with only a few pixels of each window
# visible on the left side.
#
# Later, call +swap()+, and subsequent calls to +pile+ will make a
# similar pile on the second pile.  Another call to +swap+ sets the
# target for subsequent +pile+ calls.

class Piler < ARobot

  PILE_OFFSET = 5
  def initialize
    dim = ARobot.shared_instance.screen_size

    height= dim.height
    @y1 = height / 5
    @y2 = @y1 + @y1
    @current = Point.new(PILE_OFFSET, @y1)
    @other = Point.new(PILE_OFFSET, @y2)
  end


  def pile_stack(x, y)
    point = Point.new(x, y)
    windows = []
    loop do
      w = PinnableWindow.from_point(point)
      break unless w

      w.set_default_refresh_loc('lc')
      windows << w
      pile(w)
    end
    windows    
  end
  

  def swap
    t = @current
    @current = @other
    @other = t
    @current.x = PILE_OFFSET
  end

  # Add a window to the "current" pile.
  def pile(w)
    w.drag_to(@current)
    w.set_default_refresh_loc('lc')
    @current.x += PILE_OFFSET
  end
end

class Pile

  def initialize(y_start, min_height)
  end

  # Add to pile.  Drag it to new screen location.
  def put(w)
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
    # the two heights.  Same with width.
    #
    # XXX Need to know, actually, the "minimum width" for the window,
    # so we can make sure it's refresh-able even at min size, with
    # max-size neighbors.
    prev_height = pinnable.rect.height
    with_robot_lock do
      pinnable.drag_to(Point.new(@xtile, @ytile))

      curr_height = pinnable.rect.height
      use_height = [prev_height, curr_height, @min_height].max
      x_incr = ((1.0 - @ovlp) * width ).to_i
      @xtile += x_incr
      @ymax = [@ymax, @ytile + use_height].max
    end

    pinnable
  end
end
