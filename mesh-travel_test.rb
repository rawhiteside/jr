require 'test/unit'
require 'mesh-travel'

class MeshGraphTest <  Test::Unit::TestCase
  def setup
    @mesh_fixture = [
      [[0,0], [0,2]],
      [[0,2], [2,2]],
      [[0,0], [2,2]],  
    ]
    @mg = MeshGraph.new(@mesh_fixture)

  end

  def test_init
    g = @mg.graph
    verts = g.vertices
    expected_verts = [[0,0], [0,2], [2,2]]

    assert_equal(expected_verts.size, verts.size)

    expected_verts.each {|v| assert(verts.include?(v))}
    assert_equal(g.edges.size, 3)
  end

  def test_find_closest_node
    assert_equal([0,0], @mg.find_closest_node([0,0]))
    assert_equal([0,0], @mg.find_closest_node([1,0]))
    assert_equal([0,0], @mg.find_closest_node([0,-1]))
    assert_equal([2,2], @mg.find_closest_node([3,3]))
    assert_equal([2,2], @mg.find_closest_node([2,2]))
  end

  def test_find_closest_edge
    e = @mg.find_closest_edge([1,1])
    assert_equal([[0,0], [2,2]], [e[0], e[1]])
  end

  def test_closest_point_on_lineseg
    assert_equal([0,0], @mg.closest_point_on_lineseg([0,0], [2,2], [0,-1]))
  end

  def test_get_path
    assert_equal([[0,0], [0,2]], @mg.get_path([0,0], [0,2]))
    assert_equal([[0,0], [2,2]], @mg.get_path([0,0], [2,2]))
    assert_equal([[0,0], [2,2], [3,3]], @mg.get_path([0,0], [3,3]))
    assert_equal([[0,0], [2,2]], @mg.get_path([-1,0], [2,2]))
    assert_equal([[0,0], [2,2], [3,3]], @mg.get_path([-1,0], [3,3]))

    assert_equal([[0,1], [0,2], [2,2], [3,3]], @mg.get_path([-1, 1], [3,3]))

    
    
  end
end
