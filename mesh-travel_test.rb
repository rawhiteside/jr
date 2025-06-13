require 'test/unit'
require 'mesh-travel'

class MeshGraphTest <  Test::Unit::TestCase
  def setup
    @mesh_fixture = [
      [[0,0], [0,2]],
      [[0,2], [2,2]],
      [[0,0], [2,2]],  
    ]

  end

  def test_init
    g = MeshGraph.new(@mesh_fixture).graph
    assert(g.vertices.include?([0,0]))
  end

end
