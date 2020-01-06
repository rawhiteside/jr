module Utils

  def travel(dest)
    Travel.new.travel_to(dest)
  end

  def dismiss_all
    AWindow.dismiss_all
  end

  def fill_jugs
    send_string('7')
    HowMuch.max
  end

  # Is the skill-name present and non-red?
  def stat_ok?(skill_name)
    sw = SkillsWindow.new
    color = sw.text_color(skill_name)
    if color.nil? || color == :red || color == 'red'
      return false
    else
      return true
    end
  end

  # Walk from here to the provided (x, y) location.  Path must be
  # clear.
  def walk(x, y)
    Walker.new.walk_to([x, y])
  end

  # Read the chat window (which must be generally at teh lower left,
  # with all of the borders visible.
  def read_chat
    return SkillsWindow.new.read_text
  end

  # Wait for a stat to be non-red in the skills window
  # 'Can't-find-stat' means the same as :red
  def stat_wait(arr)

    arr = [arr] unless arr.kind_of?(Array)

    loop do
      all_ok = true
      arr.each do |stat|
	all_ok = all_ok && stat_ok?(stat)
      end
      return if all_ok
      sleep 1
    end
  end

end

#
# Holds context for run-and-do.
# Needs a better name, methinks.
#
class RunAndDoContext < ARobot
  include Utils

  def initialze
    super
  end
  

  # send hotkeys to the screen.  Used for, for example, gathering wood
  # from trees, resin from trees, and the greehouses.
  # 
  def spam(str, gridx = 10, gridy = 8)
    dim = screen_size
    x_size = dim.width/gridx
    y_size = dim.height/gridy
    1.upto(gridy - 1) do |y|
      1.upto(gridx - 1) do |x|
        mm x * x_size, y * y_size
        send_string str, 0.03
      end
    end
  end
end
