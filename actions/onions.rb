require 'action.rb'
require 'window'
require 'pixel_block'

class Onions < Action
  def initialize(name = "Grow onions", category = 'Plants')
    super(name, category)
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Drag onto your head', :name => 'head'},
      {:type => :point, :label => 'Drag onto plant button', :name => 'plant'},
    ]
    @vals =  UserIO.prompt(parent, 'onions', 'onions', gadgets)
  end

  def act
    plant_win = PinnableWindow.from_point(Point.new(@vals['plant.x'].to_i, @vals['plant.y'].to_i))
    plant_point = Point.new(plant_win.rect.width/2, plant_win.rect.height/2)
    plant_win.dialog_click(plant_point)
  end
end



Action.add_action(Onions.new)

