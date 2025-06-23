require 'test/unit'
require './mesh-canon.rb'
require './action-setup-ui.rb'

java_import java.awt.Point
java_import java.awt.Rectangle

P00_00 = Point.new(0,0)

P00_10 = Point.new(0,10)
P00_20 = Point.new(0,20)

P10_00 = Point.new(10,0)
P20_00 = Point.new(20,0)

P10_10 = Point.new(10, 10)
P20_20 = Point.new(20, 20)
P30_30 = Point.new(30, 30)

P30_20 = Point.new(30, 20)

P10_20 = Point.new(10, 20)
P20_10 = Point.new(20, 10)

class LoadTravelPathTest <  Test::Unit::TestCase
  def setup
    
  end

  def segs_from_coords(coords)
    segs = []
    prev = nil
    coords.each do |xy|
      p = Point.new(xy[0], xy[1])
      segs << LineSeg.new(prev, p) if prev
      prev = p
    end

    segs
  end

  def test_load_save
    m1 = [[[0,0], [50,0]], [[0,10], [50,10]], [[0,20], [50,20]]]
    file = "test-path.yaml"
    File.open(file, 'w') {|f| YAML.dump(m1, f)}

    # Now load,
    canon = CanonicalLineSegList.load(file)
    m2 = canon.to_a
    assert_equal(m1, m2)

    # and save it and reload.
    canon.save("test-path.yaml")
    m3 = CanonicalLineSegList.load(file).to_a
    assert_equal(m1, m3)

  end

end


class CanonicalLineSegListTest < Test::Unit::TestCase
  def p(x, y)
    Point.new(x, y)
  end

  #  |
  #  |
  #
  #  _______
  def test_connect_nearby_nodes
    seg_h = [[0,0],[5,0]]
    seg_v = [[0,1],[0,5]]
    segs = [ seg_h, seg_v, ]
    canon = CanonicalLineSegList.new
    canon.add_xy(segs)
    expected = [seg_h, seg_v, [[0,0],[0,1]]]
    assert_equal(expected, canon.to_a)
  end

  #    | |
  #  --------
  #    | |
  def test_crosses
    seg_h = LineSeg.new(p(0,10),p(30,10))
    seg_v1 = LineSeg.new(p(10,0), p(10,20))
    seg_v2 = LineSeg.new(p(20,0), p(20,20))
    expected = [
      LineSeg.new(p(0,10),p(10,10)), LineSeg.new(p(10,10),p(20,10)), LineSeg.new(p(20,10),p(30,10)),
      LineSeg.new(p(10,0),p(10,10)), LineSeg.new(p(10,10),p(10,20)),
      LineSeg.new(p(20,0),p(20,10)), LineSeg.new(p(20,10),p(20,20)),
    ]

    segs = [seg_h, seg_v1, seg_v2]

    canon = CanonicalLineSegList.new
    segs.each {|seg| canon.add(seg)}
    assert_equal(expected.size, canon.line_segs.size)
    expect(canon, expected)

    canon = CanonicalLineSegList.new
    segs = segs.rotate(1)
    segs.each {|seg| canon.add(seg)}
    assert_equal(expected.size, canon.line_segs.size)
    expect(canon, expected)

    canon = CanonicalLineSegList.new
    segs = segs.rotate(1)
    segs.each {|seg| canon.add(seg)}
    assert_equal(expected.size, canon.line_segs.size)
    expect(canon, expected)

  end

  # The two segments intersect at a non-terminus point.
  def test_add_intersection
    # Intersection at (10,10)
    canon = CanonicalLineSegList.new
    canon.add(LineSeg.new(p(0,0), p(20,20)))
    canon.add(LineSeg.new(p(0,20), p(20,0)))
    assert_equal(4, canon.line_segs.size)
    expect(canon, 
      [
        LineSeg.new(p(0,0), p(10,10)), LineSeg.new(p(10,10), p(20,20)),
        LineSeg.new(p(0,20), p(10,10)), LineSeg.new(p(10,10), p(20,0))
      ]
    )
              
  end

  # The two segments intersect at a non-terminus point.
  def test_add_xy_intersection
    # Intersection at (10,10)
    canon = CanonicalLineSegList.new
    xy = [ [[0,0],[20,20]], [[0,20],[20,0]] ]
    canon.add_xy(xy)
    assert_equal(4, canon.line_segs.size)
    expect(canon, 
      [
        LineSeg.new(p(0,0), p(10,10)), LineSeg.new(p(10,10), p(20,20)),
        LineSeg.new(p(0,20), p(10,10)), LineSeg.new(p(10,10), p(20,0))
      ]
    )
              
  end


  # One seg terminates along the line of the other.  This should
  # result in one segment being split into two.
  def test_add_midpoint_terminus

    expected_segs1 = [LineSeg.new(p(0,0), p(10, 0)), LineSeg.new(p(10, 0), p(20, 0)), LineSeg.new(p(10,0), p(10,10))]
    expected_segs2 = [LineSeg.new(p(0,0), p(10, 0)), LineSeg.new(p(10, 0), p(20, 0)), LineSeg.new(p(10,10), p(10,0))]

    # new/1: new segment has its point 1 along the other segment.
    canon = CanonicalLineSegList.new
    canon.add(LineSeg.new(p(0,0), p(20,0)))
    canon.add(LineSeg.new(p(10,0), p(10,10)))
    assert_equal( 3, canon.line_segs.size)
    expect(canon, expected_segs1)


    # new/2: new segment has its point 2 along the other segment.
    canon = CanonicalLineSegList.new
    canon.add(LineSeg.new(p(0,0), p(20,0)))
    canon.add(LineSeg.new(p(10,10), p(10,0)))
    assert_equal(3, canon.line_segs.size)
    expect(canon, expected_segs2)
    
    # old/1: old segment has its point 1 along the other segment.
    canon = CanonicalLineSegList.new
    canon.add(LineSeg.new(p(10,0), p(10,10)))
    canon.add(LineSeg.new(p(0,0), p(20,0)))
    assert_equal(3, canon.line_segs.size)
    expect(canon, expected_segs1)


    # old/2: old segment has its point 2 along the other segment.
    canon = CanonicalLineSegList.new
    canon.add(LineSeg.new(p(10,10), p(10,0)))
    canon.add(LineSeg.new(p(0,0), p(20,0)))
    assert_equal(3, canon.line_segs.size)
    expect(canon, expected_segs2)


  end


  def test_add_endpoint_terminus

    # Add a seg, then one that intersects only at a segment endpoint.
    # (1, 1): First point of pt1, first point of pt2
    canon = CanonicalLineSegList.new
    canon.add(ls0001 = LineSeg.new(p(0,0), p(0,10)))
    canon.add(ls0011 = LineSeg.new(p(0,0), p(10,10)))
    assert_equal( 2, canon.line_segs.size)
    expect(canon, [ls0001, ls0011])
    
    # (1, 2)
    canon = CanonicalLineSegList.new
    canon.add(ls0001 = LineSeg.new(p(0,0), p(0,10)))
    canon.add(ls1100 = LineSeg.new(p(10,10), p(0,0)))
    assert_equal( 2, canon.line_segs.size)
    expect(canon, [ls0001, ls1100])
    
    # (2, 1)
    canon = CanonicalLineSegList.new
    canon.add(ls0001 = LineSeg.new(p(0,0), p(0,10)))
    canon.add(ls0111 = LineSeg.new(p(0,10), p(10,10)))
    assert_equal( 2, canon.line_segs.size)
    expect(canon, [ls0001, ls0111])
    
    # (2, 2)
    canon = CanonicalLineSegList.new
    canon.add(ls0001 = LineSeg.new(p(0,0), p(0,10)))
    canon.add(ls1101 = LineSeg.new(p(10,10), p(0,10)))
    assert_equal( 2, canon.line_segs.size)
    expect(canon, [ls0001, ls1101])
    
  end

  def test_add_dup
    canon = CanonicalLineSegList.new

    # Add a seg
    canon.add(ls0011 = LineSeg.new(p(0,0), p(1,1)))
    assert_equal( 1, canon.line_segs.size)
    
    # Add a  dup
    canon.add(LineSeg.new(p(0,0), p(1,1)))
    assert_equal( 1, canon.line_segs.size)

    # Add a new one
    canon.add(ls0010 = LineSeg.new(p(0,0), p(1,0)))
    assert_equal( 2, canon.line_segs.size)

    # and more dups
    canon.add(LineSeg.new(p(0,0), p(1,0)))
    assert_equal( 2, canon.line_segs.size)
    canon.add(LineSeg.new(p(0,0), p(1,1)))
    assert_equal( 2, canon.line_segs.size)
    expect(canon, [ls0011, ls0010])
  end

  def test_misses()
    canon = CanonicalLineSegList.new

    # Two segs with overlapping bounds.
    # - long diagonal, then a non-intersecting hoizontal/vertical.
    canon.add(ls0055 = LineSeg.new(p(0,0), p(5,5)))
    canon.add(ls3236 = LineSeg.new(p(3,2), p(6,2)))
    assert_equal(2, canon.line_segs.size)
    canon.add(ls2326 = LineSeg.new(p(2,3), p(2,6)))
    assert_equal(3, canon.line_segs.size)
    expect(canon, [ls0055, ls3236, ls2326])

    # Segs sharing node.
    canon = CanonicalLineSegList.new
    canon.add(ls0001 = LineSeg.new(p(0,0), p(0,1)))
    assert_equal(1, canon.line_segs.size)
    canon.add(ls0010 = LineSeg.new(p(0,0), p(1,0)))
    assert_equal(2, canon.line_segs.size)
    canon.add(ls1100 = LineSeg.new(p(1,1), p(0,0)))
    assert_equal(3, canon.line_segs.size)
    expect(canon, [ls0001, ls0010, ls1100])
  end

  def test_dup
    canon = CanonicalLineSegList.new
    canon.add(ls0001 = LineSeg.new(p(0,0), p(0,1)))
    assert_equal(1, canon.line_segs.size)

    # straight dup.
    canon.add(ls0001 = LineSeg.new(p(0,0), p(0,1)))
    assert_equal(1, canon.line_segs.size)

    # Dup w nodes reversed.
    canon.add(LineSeg.new(p(0,1), p(0,0)))
    assert_equal(1, canon.line_segs.size)


  end

  def expect(canon, segs)
    segs.each {|seg| assert(canon.line_segs.include?(seg), seg.to_s)}
  end
end

class LineSegTest < Test::Unit::TestCase

  def test_ctor
    ls = LineSeg.new(Point.new(0,0), Point.new(1, 1))
    assert_not_nil(ls)
    assert_equal(ls.pt1, Point.new(0,0))
    assert_equal(ls.pt2, Point.new(1,1))
  end

  def test_rect
    assert_equal(LineSeg.new(P00_00, P10_10).rect.to_s, Rectangle.new(0, 0, 11, 11).to_s)
    assert_equal(LineSeg.new(P10_10, P00_00).rect.to_s, Rectangle.new(0, 0, 11, 11).to_s)

    assert_equal(LineSeg.new(P00_10, P10_00).rect.to_s, Rectangle.new(0, 0, 11, 11).to_s)
    assert_equal(LineSeg.new(P10_00, P00_10).rect.to_s, Rectangle.new(0, 0, 11, 11).to_s)


    assert_equal(LineSeg.new(P00_00, P20_20).rect.to_s, Rectangle.new(0, 0, 21, 21).to_s)
    assert_equal(LineSeg.new(P20_20, P00_00).rect.to_s, Rectangle.new(0, 0, 21, 21).to_s)


    assert_equal(LineSeg.new(P00_00, P00_10).rect.to_s, Rectangle.new(0, 0, 1, 11).to_s)
    assert_equal(LineSeg.new(P00_00, P10_00).rect.to_s, Rectangle.new(0, 0, 11, 1).to_s)

  end

  def test_equal
    assert(LineSeg.new(P00_00, P10_10) == LineSeg.new(P00_00, P10_10))

    assert(LineSeg.new(P00_00, P10_10) == LineSeg.new(P00_00, P10_10))

    assert(LineSeg.new(P00_00, P10_10) != LineSeg.new(P10_10, P20_20))
    assert(!(LineSeg.new(P00_00, P10_10) == LineSeg.new(P10_10, P20_20)))
  end

  def test_rect_overlaps
    assert(LineSeg.new(P00_00, P10_10).rect_overlaps?(LineSeg.new(P00_00, P10_10)))
    assert(LineSeg.new(P00_00, P10_10).rect_overlaps?(LineSeg.new(P10_10, P00_00)))
    assert(LineSeg.new(P00_00, P20_20).rect_overlaps?(LineSeg.new(P00_00, P10_10)))
    assert(LineSeg.new(P00_00, P10_10).rect_overlaps?(LineSeg.new(P00_00, P20_20)))
    
    assert_false(LineSeg.new(P00_00, P00_10).rect_overlaps?(LineSeg.new(P10_10, P20_20)))
    assert_false(LineSeg.new(P10_10, P20_20).rect_overlaps?(LineSeg.new(P00_00, P00_10)))

    assert(LineSeg.new(P00_00, P10_10).rect_overlaps?(LineSeg.new(P10_10, P20_20)))
    assert(LineSeg.new(P20_20, P10_10).rect_overlaps?(LineSeg.new(P10_10, P00_00)))

    # Cases where overlap, but no intersect.
    assert(LineSeg.new(P00_00, P30_30).rect_overlaps?(LineSeg.new(P20_10, P20_00)))
    assert(LineSeg.new(P00_00, P30_30).rect_overlaps?(LineSeg.new(P10_20, P00_20)))
    assert(LineSeg.new(P00_00, P30_30).rect_overlaps?(LineSeg.new(P00_20, P10_20)))
    
  end

  def test_intersect
    # Don't overlap
    assert_nil(LineSeg.new(P00_00, P00_10).intersection(LineSeg.new(P10_10, P20_20)))

    # Parallel
    assert_nil(LineSeg.new(P00_00, P10_00).intersection(LineSeg.new(P00_10, P10_10)))
    assert_nil(LineSeg.new(P00_00, P00_10).intersection(LineSeg.new(P10_00, P10_20)))

    # Intersections
    assert_equal(LineSeg.new(P00_00, P20_20).intersection(LineSeg.new(P10_00, P10_20)).to_s, Point.new(10, 10).to_s)
    
    # This one should fail, as while the rects overlap, there's no
    # intersection in the segments themselves.
    assert_nil(LineSeg.new(P00_00, P30_30).intersection(LineSeg.new(P20_10, P20_00)))
    assert_nil(LineSeg.new(P00_00, P30_30).intersection(LineSeg.new(P10_20, P00_20)))
    assert_nil(LineSeg.new(P00_00, P30_30).intersection(LineSeg.new(P00_20, P10_20)))
    
    # And one that hits 1/3 and 2/3 between points
    ls1 = LineSeg.new(P00_00, P30_20)
    
    assert_equal(ls1.intersection(LineSeg.new(P10_00, P10_10)), Point.new(10, 7))
    assert_equal(ls1.intersection(LineSeg.new(P20_10, P20_20)).to_s, Point.new(20, 13).to_s)

  end

end
