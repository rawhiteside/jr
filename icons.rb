require 'window.rb'

# Handes the Icons that appear in the UL.
class Icons

  REF_CENTER_X = 960
  REF_HEIGHT = 1080

  ICON_DATA = {
    :grass => {:x => 713 - REF_CENTER_X, :y => 1015 - REF_HEIGHT, :hot_key => '1'},
    :sand => {:hot_key => '2' },
    :mud => {:hot_key => '3' },
    :clay => {:x => 920 - REF_CENTER_X, :y => 1039 - REF_HEIGHT, :hot_key => '4'},
    :dirt => {:hot_key => '5'},
    :limestone => {:hot_key => '6'},
    :water => { :hot_key => '7' },
    :slate => {:x => 1191 - REF_CENTER_X, :y => 1004 - REF_HEIGHT, :hot_key => '8'},
    :dowse => {:hot_key => '9' },
    
  }
  # what to do next?: 2 wide
  # Pyramid, mud, water, (sand|grass|..), slate, just-in-case
  MAX_ICONS = 8
  
  def self.to_screen(y)
    @@y_off ||= compute_y_off
    y + @@y_off
  end


  def self.hotkey_for(which)
    ICON_DATA[which][:hot_key]
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
    robot = ARobot.shared_instance
    robot.with_robot_lock do
      robot.send_string(hotkey_for(:water))
      HowMuch.max
      robot.sleep_sec 0.1 
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
