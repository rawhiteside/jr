#
# It appears this was to provide access to things *not* directly in robot. 
#

# Ooooh.  Maybe it was for the camp worker.
# 
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

