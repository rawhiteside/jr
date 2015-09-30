require 'action'
require 'walker'
require 'user-io'
require 'actions/stat_clicks'

import org.foa.window.ClockLocWindow

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
    stat_wait('Focus')
    # If the food is gone, stop dowsing.
    return :stop if @eat.should_eat?
    rclick_at(88, 79)
  end

  def make_path(center)
    [
      [0,-25], [0,-20], [0,-15], [0,-10], [0,-5], [0,0], [0, 5], [0,10], [0,15], [0,20], [0,25],
      [5,-20], [5,-15], [5,-10], [5,-5], [5,0], [5, 5], [5,10], [5,15], [5,20], 
      [10,-15], [10,-10], [10,-5], [10,0], [10, 5], [10,10], [10,15], 
      [15,-10], [15,-5], [15,0], [15, 5], [15,10], 
      [20,-5], [20,0], [20,5], 
      [25,0],
      [-5,-20], [-5,-15], [-5,-10], [-5,-5], [-5,0], [-5, 5], [-5,10], [-5,15], [-5,20], 
      [-10,-15], [-10,-10], [-10,-5], [-10,0], [-10, 5], [-10,10], [-10,15], 
      [-15,-10], [-15,-5], [-15,0], [-15, 5], [-15,10], 
      [-20,-5], [-20,0], [-20,5], 
      [-25,0],
    ].collect {|xy| [center[0] + xy[0], center[1] + xy[1]]}
  end

end
Action.add_action(StrontDowse.new)
