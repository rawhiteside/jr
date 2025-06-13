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


class AddMeshDest < Action
  def initialize
    super('Add Mesh Destination', 'Misc')
  end
  def persistence_name
    'add_mesh_dest'
  end

  def setup(parent)
    gadgets = [
      {:type => :text, :label => "Destination", :name => "name", :size => 20},
      {:type => :world_loc, :label => "Coordinates", :name => 'loc'}
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    dest_name = @vals['name']
    dest_coords = WorldLocUtils.parse_world_location(@vals['loc'])
    file = "mesh-destinations.yaml"
    name_map = {}
    name_map = YAML.load_file(file) if File.exist?(file)
    name_map[dest_name] = dest_coords
    File.open(file, 'w') {|f| YAML.dump(name_map, f)}
  end
end
Action.add_action(AddMeshDest.new)


class MeshTravel < Action
  def initialize
    super('Travel mesh', 'Misc')
  end
  def persistence_name
    'travel_mesh'
  end

  def setup(parent)
    file = "mesh-destinations.yaml"
    @dest_map = YAML.load_file(file)
    gadgets = [
      {:type => :combo, :label => "Destination", :name => "dest", :vals => @dest_map.keys},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    # - Build AdjGraph
    # - Find closest node to dest

    # - !!! Find closest lineseg
    # - - Find all verts that connect to dest.
    # - - Find all the edges that have those vertices.
    # - - Find the edge closest to current location.
    # - - If a vert is closest to current location
    # - - - just use that vert for dijk.
    # - - - run 2 node, run through mesh, run to dest.

    # - - else
    # - - - find closest point along the edge.
    # - - - figure which of the two nodes is closest to dest.
    # - - - run to intercept, run to node, run throuth mesh, run to dest.
    # - - -
    
    dest = @vals['dest']
    puts dest
  end
end
Action.add_action(MeshTravel.new)
