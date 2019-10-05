require 'action'

class WalkTo < Action
  def initialize
    super('Walk', 'Misc')
  end

  def setup(parent)
    gadgets = [
      {:type => :number, :label => 'Destination x coordinate', :name => 'dest_x'},
      {:type => :number, :label => 'Destination y coordinate', :name => 'dest_y'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    x = @vals['dest_x'].to_i
    y = @vals['dest_y'].to_i
    Walker.new.walk_to([x, y])
  end
end

Action.add_action(WalkTo.new)

