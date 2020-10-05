require 'window.rb'

# Handes the Icons that appear on the action bar
class Icons

  ICON_DATA = {
    :grass => {:image => 'GrassIcon.png',:hot_key => '1'},
    :sand => {:image => 'SandIcon.png', :hot_key => '2' },
    :mud => {:image => 'MudIcon.png', :hot_key => '3' },
    :clay => {:image => 'ClayIcon.png', :hot_key => '4'},
    :dirt => {:image => 'DirtIcon.png', :hot_key => '5'},
    :limestone => {:image => 'LimestoneIcon.png', :hot_key => '6'},
    :water => {:image => 'WaterIcon.png',  :hot_key => '7' },
    :slate => {:image => 'SlateIcon.png',  :hot_key => '8'},
    :dowse => {:image => 'DowseIcon.png', :hot_key => '9' },
    
  }
  

  # Click on the icon if it's there.  Returns success-p
  def self.hotkey_if_active(icon)
    robot = ARobot.shared_instance
    dim = robot.screen_size
    data = ICON_DATA[icon]
    if lit_up(data[:image])
      robot.send_string(data[:hot_key])
      return true
    end

    return false
  end

  CENTER_OFFSET = 375
  BOTTOM_OFFSET = 180
  @@template_hash = {}
  def self.lit_up(image_file)
    dim = ARobot.shared_instance.screen_size
    x = dim.width/2 - CENTER_OFFSET
    width = CENTER_OFFSET * 2
    y = dim.height - BOTTOM_OFFSET
    rect = Rectangle.new(x, y, width, BOTTOM_OFFSET)
    image = PixelBlock.new(rect)

    template = load_template(image_file)
    pt = image.find_template_exact(template)
    pt = image.to_screen(pt) if pt
    return pt
  end

  def self.load_template(name)
    template = @@template_hash[name]
    if template.nil?
      filename = "images/#{name}"
      template = PixelBlock.load_image(filename)
      @@template_hash[name] = template
    end
    return template
  end

  # Specifically for filling water jugs.
  def self.refill
    data = ICON_DATA[:water]
    robot = ARobot.shared_instance
    robot.with_robot_lock do
      robot.send_string(data[:hot_key])
      HowMuch.max
      robot.sleep 0.1 
    end
  end
end
