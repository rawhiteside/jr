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
    verts = g.vertices
    expected_verts = [[0,0], [0,2], [2,2]]

    assert_equal(expected_verts.size, verts.size)

    expected_verts.each {|v| assert(verts.include?(v))}
    assert_equal(g.edges.size, 3)
  end

end
