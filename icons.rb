require 'window.rb'

# Handes the Icons that appear in the UL.
class Icons

  # Y coords are in "atitd window" coords, not screen.
  # x coords are offsets within the 64-bit icon. 
  ICON_DATA = {
    :water => { :x => 17, :y => 74, :pixel => 0x5d81c1},
    :clay => {:x => 40, :y => 84, :pixel => 0xd06c55},
    :slate => {:x => 285, :y => 95 - 23, :pixel => 0x797978},
    :grass => {:x => 220, :y => (86 - 23), :pixel => 0x2bc00e},
    :dowse => {:x => 94, :y => (64 - 23), :pixel => 0xa67b44},
  }
  # what to do next?: 2 wide
  # Pyramid, mud, water, (sand|grass|..), slate, just-in-case
  MAX_ICONS = 8
  
  def self.to_screen(y)
    @@y_off ||= compute_y_off
    y + @@y_off
  end

  # Try to find the icon and click on it if it's found.  Returns
  # whether successful.
  def self.try_click(x, y, pixel)
    x = find_icon(x, y, pixel)
    if x
      ARobot.shared_instance.rclick_at_restore(x, y)
      return true
    end
    return false
  end

  # Click on the icon if it's there.  Returns success-p
  def self.click_on(icon)
    data = ICON_DATA[icon]
    y = to_screen(data[:y])
    x = data[:x] % 64

    try_click(x, y, data[:pixel])
  end

  # Specifically for filling water jugs.
  def self.refill
      ARobot.shared_instance.with_robot_lock do
        if (click_on(:water))
          HowMuch.max
	  ARobot.shared_instance.sleep_sec 0.1 
        else
          UserIO.error("Didn't find the water icon.")
        end
      end
  end


  # Searches for the provided pixel along the provided y value.
  # X is the mod 64 value for the x coord.
  def self.find_icon(x, y, pixel)
    rect = Rectangle.new(0, y, 64*MAX_ICONS, 1)
    pb = PixelBlock.new(rect)
    MAX_ICONS.times do
      return x if pb.pixel(x, 0) == pixel
      x += 64
    end

    nil
  end

  # Is this a hack?  I think it's a hack.  The ClockLoc window is at
  # the top of the ATITD client area.
  def self.compute_y_off
    ClockLocWindow.instance.rect.y
  end

end
