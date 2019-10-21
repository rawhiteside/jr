
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

end
