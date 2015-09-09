require 'test/unit'
require 'bounds.rb'

class BoundsTest < Test::Unit::TestCase
  def test_ctor_point
    b = Bounds.new([5, 6])
    assert_equal(5, b.xmax)
    assert_equal(5, b.xmin)
    assert_equal(6, b.ymax)
    assert_equal(6, b.ymin)

    assert_equal(0, b.xradius)
    assert_equal(0, b.yradius)

    assert_equal(5, b.xcenter)
    assert_equal(6, b.ycenter)

    assert(!b.contains?([5, 7]))
    assert(!b.contains?([7, 6]))

    assert(b.contains?([5, 6]))
  end

  def test_overlap_point
    b1 = Bounds.new([5, 6])
    assert(b1.overlaps?(b1))
    assert_equal(0, b1.offset_for(b1))

    b2 = Bounds.new([7, 8])
    assert(!b1.overlaps?(b2))
    assert(!b2.overlaps?(b1))

    assert_equal(4, b1.offset_for(b2))
  end

  def test_add
    b1 = Bounds.new([5, 6])
    b1.add([7, 8])
    assert_equal(5, b1.xmin)
    assert_equal(7, b1.xmax)

    assert_equal(6, b1.ymin)
    assert_equal(8, b1.ymax)

    assert_equal(1, b1.xradius)
    assert_equal(1, b1.yradius)

    assert_equal(6, b1.xcenter)
    assert_equal(7, b1.ycenter)
  end

  def test_rect_contains
    b1 = Bounds.new([10, 15])
    b1.add([20, 35])
    assert(b1.contains?([11, 16]))
    assert(b1.contains?([10, 15]))
    assert(b1.contains?([20, 35]))
  end

  def test_rect_union
    b1 = Bounds.new([10, 15])
    b2 = Bounds.new([20, 35])
    b1.union!(b2)
    assert(b1.contains?([11, 16]))
    assert(b1.contains?([10, 15]))
    assert(b1.contains?([20, 35]))

    assert(!b1.contains?([9, 16]))
    assert(!b1.contains?([21, 16]))
    assert(!b1.contains?([11, 14]))
    assert(!b1.contains?([11, 36]))
  end

  def test_overlaps
    b1 = Bounds.new([20, 20])
    b1.add([25, 25])

    # Completely inside B1
    b2 = Bounds.new([21, 21])
    b2.add([22, 22])
    assert(b1.overlaps?(b2))
    assert(b2.overlaps?(b1))

    # Shares a point
    b2 = Bounds.new([20, 20])
    b2.add([10, 10])
    assert(b1.overlaps?(b2))
    assert(b2.overlaps?(b1))

    # No overlap
    b2 = Bounds.new([19, 19])
    b2.add([10, 10])
    assert(!b1.overlaps?(b2))
    assert(!b2.overlaps?(b1))

    # and a long thin overlap
    b2 = Bounds.new([0, 22])
    b2.add([50, 23])
    assert(b1.overlaps?(b2))
    assert(b2.overlaps?(b1))
    
  end

  def test_strip_for
    b = Bounds.new([5, 5], [10, 10])
    strip = b.strip_for([6,6], 2, [1, 0])
    assert_equal(2, strip.size)
    assert_equal([[6,6], [7,6]], strip)

    strip = b.strip_for([0, 6], 2, [1, 0])
    assert_equal(0, strip.size)

    strip = b.strip_for([4, 6], 2, [1, 0])
    assert_equal(1, strip.size)
    assert_equal([[5, 6]], strip)

    strip = b.strip_for([9, 6], 2, [1, 0])
    assert_equal(1, strip.size)
    assert_equal([[9, 6]], strip)


    strip = b.strip_for([6, 6], 2, [0, 1])
    assert_equal(2, strip.size)
    assert_equal([[6,6], [6,7]], strip)
  end

  def test_spiral_for_radius
    b = Bounds.new([0,10],[3,15])

    # Central point
    pts = b.spiral_for_radius(0)
    assert_equal([[1, 12]], pts)

    # Radius too big
    pts = b.spiral_for_radius(100)
    assert_equal([], pts)

    pts = b.spiral_for_radius(1)
    # Tests to much:  order of points
    expected = [
      [0, 11], [1, 11], [2, 11],
      [0, 13], [1, 13], [2, 13],
      [0, 12],
      [2, 12],
    ]
    assert_equal(expected, pts)

    # Gets just the top and bot rows
    pts = b.spiral_for_radius(2)
    expected = [
      [0, 10], [1, 10], [2, 10],
      [0, 14], [1, 14], [2, 14],
    ]
    assert_equal(expected, pts)
  end

  def test_spiral
    b = Bounds.new([0,0], [3,3])
    pts = b.spiral
    expected = [
      [1, 1],
      [0, 0], [1, 0], [2, 0],
      [0, 2], [1, 2], [2, 2],
      [0, 1],
      [2, 1]
    ]
    assert_equal(expected, b.spiral)
  end
end
