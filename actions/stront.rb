require 'action'
require 'walker'
require 'user-io'

java_import org.foa.window.ClockLocWindow

class StrontDowse < Action

  def initialize
    super('Dowse Strontium', 'Misc')
  end

  def get_starting_coords
    win = ClockLocWindow.instance
    if win 
      return win.coords
    else
      UserIO.error('Could not read starting coordinates')
      return nil
    end
  end

  def act
    @eat = Eat.new
    center_coords = get_starting_coords
    return nil unless center_coords
    path = make_path(center_coords)

    Walker.new.walk_path(path) { dowse }

  end

  def dowse
    stat_wait :foc
    # If the food is gone, stop dowsing.
    return :stop if @eat.should_eat?
    lclick_at(88, 79)
  end

  def make_path(center)
    [
      [0, -25], [0, -18], [0, -11], [0, -4], [0, 3], [0, 10], [0, 17], [0, 24],
      [7, -18], [7, -11], [7, -4], [7, 3], [7, 10], [7, 17],
      [-7, -18], [-7, -11], [-7, -4], [-7, 3], [-7, 10], [-7, 17],
      [14, -11], [14, -4], [14, 3], [14, 10], 
      [-14, -11], [-14, -4], [-14, 3], [-14, 10], 
      [21, -4], [21, 3],
      [-21, -4], [-21, 3],
      [-28, 3],
      [27, -4],
    ].collect {|xy| [center[0] + xy[0], center[1] + xy[1]]}
  end

end
Action.add_action(StrontDowse.new)
