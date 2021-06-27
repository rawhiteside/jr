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

  def find_template_best(template, threshold)
    pb_full = PixelBlock.full_screen
    return pb_full.find_template_best(template, threshold)
  end

  def fill_jugs
    send_string('7')
    HowMuch.max
  end

  # Walk from here to the provided (x, y) location.  Path must be
  # clear.
  def walk(x, y)
    Walker.new.walk_to([x, y])
  end

  def stat_boosted?
    Stats.stat_boosted?
  end

  # Is the skill-name present and non-red?
  def stat_ok?(stat)
    Stats.stat_ok?(stat)
  end

  # Wait for a stat to be non-red in the skills window
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

class Stats
  @@boosted_image = PixelBlock.load_image("images/boosted-stat.png")
  @@image_files = {
    :acro => "acro.png",
    :str => "STR.png",
    :end => "END.png",
    :foc => "FOC.png",
    :spd => "SPD.png",
    # :per => "PER.png",
    # :dex => "DEX.png",
  }
  @@images = {}
  @@image_files.each { |k, v| @@images[k] = PixelBlock.load_image("images/#{v}")}

  def self.stat_ok?(stat)
    PixelBlock.full_screen.find_template_exact(@@images[stat]).nil?
  end

  def self.stat_boosted?
    PixelBlock.full_screen.find_template_exact(@@boosted_image)
  end
end
