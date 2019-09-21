require 'window.rb'

# Handes the Icons that appear on the action bar
class Icons

  # Center bottom on my screen, the reference. 
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
  

  # Click on the icon if it's there.  Returns success-p
  def self.hotkey_if_active(icon)
    robot = ARobot.shared_instance
    dim = robot.screen_size
    data = ICON_DATA[icon]
    if lit_up(data[:x] + dim.width / 2, data[:y] + dim.height)
      robot.send_string(data[:hot_key])
      return true
    end

    return false
  end

  def self.lit_up(x, y)
    # Look at a little 5x5 patch for bright things.
    rect = Rectangle.new(x-2, y-2, 5, 5)
    pb = PixelBlock.new(rect)


    5.times do |i|
      5.times do |j|
        return true if bright?(pb.color(i, j))
      end
    end
    return false
  end

  BRIGHT_THRESH = 400
  def self.bright?(color)
    b = color.red + color.green + color.blue
    if (b > BRIGHT_THRESH)
      return true
    else
      false
    end
    
  end

  # Specifically for filling water jugs.
  def self.refill
    data = ICON_DATA[:water]
    p data
    robot = ARobot.shared_instance
    robot.with_robot_lock do
      robot.send_string(data[:hot_key])
      HowMuch.max
      robot.sleep_sec 0.1 
    end
  end
end
