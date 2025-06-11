require 'action'
require 'pathfind.rb'

# Add points to the global mesh.

class AddMeshPaths < Action
  def initialize
    super('Add Mesh Path', 'Misc')
  end

  def persistence_name
    'add_mesh_path'
  end
  def setup(parent)
    gadgets = [
      {:type => :world_path, :label => 'Path to walk.', :name => 'path',
       :rows => 11,}
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    path_text = @vals['path']
    @coords = WorldLocUtils.parse_world_path(@vals['path'])
    p @coords
    clsl = CanonicalLineSegList.load()
    prev_xy = nil
    @coords.each do |xy|
      if prev_xy.nil?
        prev_xy = xy
      else
        clsl.add_xy([prev_xy, xy])
        prev_xy = xy
      end
    end
    clsl.save
  end
end

Action.add_action(AddMeshPaths.new)
