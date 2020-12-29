require 'test/unit'
require './path'

class PathSegmentTest < Test::Unit::TestCase
  # def setup
  # end

  # def teardown
  # end

  def test_ctor
    t_ctor(Point.new(0, 0), Point.new(1, 1))
    t_ctor(Point.new(0, 0), Point.new(-1, 1))
    t_ctor(Point.new(0, 0), Point.new(1, -1))
    t_ctor(Point.new(2, 2), Point.new(1, -1))
  end

  def t_ctor(pt1, pt2)
    ps = PathSegment.new(Point.new(pt1), Point.new(pt2))
    assert_equal(ps.pt1, pt1)
    assert_equal(ps.pt2, pt2)
  end

  def test_from_xy
    ps = PathSegment.from_xy([1, 2], [3, 4])
    assert_equal(ps, PathSegment.new(Point.new(1, 2), Point.new(3, 4)))
  end

  def test_rect
    ps = PathSegment.new(Point.new(1, 1), Point.new(3, 3))
    assert_equal(ps.rectangle, Rectangle.new(1, 1, 2, 2))

    ps = PathSegment.new(Point.new(1, 1), Point.new(3, 4))
    assert_equal(ps.rectangle, Rectangle.new(1, 1, 2, 3))
  end

  def test_overlap
    ps = PathSegment.new(Point.new(1, 1), Point.new(2, 2))
    assert_false(ps.overlap?(PathSegment.new(Point.new(5, 5), Point.new(6, 6))))
    assert_false(ps.overlap?(PathSegment.new(Point.new(2, 2), Point.new(6, 6))))
    assert_true(ps.overlap?(PathSegment.new(Point.new(0, 0),  Point.new(6, 6))))

    ps = PathSegment.new(Point.new(1, 1), Point.new(3, 3))
    assert_true(ps.overlap?(PathSegment.new(Point.new(2, 2),  Point.new(6, 6))))

  end
end
