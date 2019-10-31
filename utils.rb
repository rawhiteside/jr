#
# Holds context for run-and-do.
# Needs a better name, methinks.
#
class Utils < ARobot
  def initialze
    super
  end
  
  def travel(dest)
    Travel.new.travel_to(dest)
  end

  def fill_jugs
    send_string('7')
    HowMuch.max
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
