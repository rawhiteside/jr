require 'test/unit'
require 'mesh-travel'
require 'timer'

class MeshGraphTest <  Test::Unit::TestCase
  def setup
    mesh_fixture = make_mesh_fixture
    @mg = MeshGraph.new(mesh_fixture)
  end

  def make_mesh_fixture
    [
      [[0,0], [0,2]],
      [[0,2], [2,2]],
      [[0,0], [2,2]],  
    ]
  end

  def test_big
    segs = []
    s = 100
    0.upto(s) do |x|
      0.upto(s) do |y|
        segs << [[x, y], [x+1, y+1]]
      end
    end
    @mg = MeshGraph.new(segs)
    secs = Timer.time_this do
      p = @mg.get_path([0,0], [100,100])
    end
    puts "Time for 100x100: #{secs}"
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

  # When we just need to walk straight to dest.
  def test_just_dest_node
    assert_equal([[0,0]], @mg.get_path([-1,-1], [0,0]))
  end

  def test_get_path
    assert_equal([[0,0], [0,2]], @mg.get_path([0,0], [0,2]))
    assert_equal([[0,0], [2,2]], @mg.get_path([0,0], [2,2]))
    assert_equal([[0,0], [2,2], [3,3]], @mg.get_path([0,0], [3,3]))
    assert_equal([[0,0], [2,2]], @mg.get_path([-1,0], [2,2]))
    assert_equal([[0,0], [2,2], [3,3]], @mg.get_path([-1,0], [3,3]))

    assert_equal([[0,1], [0,2], [2,2], [3,3]], @mg.get_path([-1, 1], [3,3]))
  end

  def test_no_path
    m = make_mesh_fixture
    m << [[10,10],[11,11]]
    mg = MeshGraph.new(m)
    assert_nil(mg.get_path([10, 10], [0,0]))
  end
end
