require 'action'
require 'mesh-canon.rb'
require 'mesh-travel'
require 'pairing_heap'

# Add points to the global mesh.

class AddMeshPaths < Action
  def initialize
    super('Mesh: Add Mesh Path', 'Misc')
  end

  def persistence_name
    'add_mesh_path'
  end
  def setup(parent)
    gadgets = [
      {:type => :world_path, :label => 'Add mesh path', :name => 'path',
       :rows => 11,}
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets, nil)
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
    super('Mesh: Add Mesh Destination', 'Misc')
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
    super('Mesh: Travel', 'Misc')
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
    puts "acting"
    mesh = CanonicalLineSegList.load
    mg = MeshGraph.new(mesh.to_a)
    dest_name = @vals[:name]
    dest_xy = @dest_map[dest_name]
    puts dest_name
    puts dest_xy
    curr_xy = ClockLocWindow.instance.coords.to_a
    puts "Starty: #{curr_xy}"
    path = mg.get_path(curr_xy, dest_xy)
  end
end
Action.add_action(MeshTravel.new)
