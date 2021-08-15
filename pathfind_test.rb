require 'test/unit'
require './pathfind.rb'
require './action-setup-ui.rb'

import java.awt.Point
import java.awt.Rectangle

P00 = Point.new(0,0)

P01 = Point.new(0,1)
P02 = Point.new(0,2)

P10 = Point.new(1,0)
P20 = Point.new(2,0)

P11 = Point.new(1, 1)
P22 = Point.new(2, 2)
P33 = Point.new(3, 3)

P32 = Point.new(3, 2)

P12 = Point.new(1, 2)
P21 = Point.new(2, 1)

class LoadTravelPathTest <  Test::Unit::TestCase
  def setup
     @travel_paths = DialogDefaults.get_defaults('Travel paths')
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

  def test_load
    canon = CanonicalLineSegList.new
    count = 0
    @travel_paths.keys.each do |key|
      next unless key.kind_of?(String)
      locs = key.to_s.split(/ to /)
      next unless locs.size == 2
      coords = WorldLocUtils.parse_world_path(@travel_paths[key]['path']).keep_if{|elt| elt.kind_of?(Array)}
      #puts "#{locs[0]}: #{coords[0]}}"
      #puts "#{locs[1]}: #{coords[-1]}}"
      segs = segs_from_coords(coords)
      segs.each { |seg| canon.add(seg) ; count += 1 }
    end
    #puts "Count added: #{count}, count canonical: #{canon.line_segs.size}"
  end
end


class CanonicalLineSegListTest < Test::Unit::TestCase
  def p(x, y)
    Point.new(x, y)
  end

  #    | |
  #  --------
  #    | |
  
  def test_crosses
    seg_h = LineSeg.new(p(0,1),p(3,1))
    seg_v1 = LineSeg.new(p(1,0), p(1,2))
    seg_v2 = LineSeg.new(p(2,0), p(2,2))
    expected = [
      LineSeg.new(p(0,1),p(1,1)), LineSeg.new(p(1,1),p(2,1)), LineSeg.new(p(2,1),p(3,1)),
      LineSeg.new(p(1,0),p(1,1)), LineSeg.new(p(1,1),p(1,2)),
      LineSeg.new(p(2,0),p(2,1)), LineSeg.new(p(2,1),p(2,2)),
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
    # Intersection at (1,1)
    canon = CanonicalLineSegList.new
    canon.add(LineSeg.new(p(0,0), p(2,2)))
    canon.add(LineSeg.new(p(0,2), p(2,0)))
    assert_equal(4, canon.line_segs.size)
    expect(canon, 
      [
        LineSeg.new(p(0,0), p(1,1)), LineSeg.new(p(1,1), p(2,2)),
        LineSeg.new(p(0,2), p(1,1)), LineSeg.new(p(1,1), p(2,0))
      ]
    )
              
  end


  # One seg terminates along the line of the other.  This should
  # result in one segment being split into two.
  def test_add_midpoint_terminus

    expected_segs1 = [LineSeg.new(p(0,0), p(1, 0)), LineSeg.new(p(1, 0), p(2, 0)), LineSeg.new(p(1,0), p(1,1))]
    expected_segs2 = [LineSeg.new(p(0,0), p(1, 0)), LineSeg.new(p(1, 0), p(2, 0)), LineSeg.new(p(1,1), p(1,0))]

    # new/1: new segment has its point 1 along the other segment.
    canon = CanonicalLineSegList.new
    canon.add(LineSeg.new(p(0,0), p(2,0)))
    canon.add(LineSeg.new(p(1,0), p(1,1)))
    assert_equal( 3, canon.line_segs.size)
    expect(canon, expected_segs1)


    # new/2: new segment has its point 2 along the other segment.
    canon = CanonicalLineSegList.new
    canon.add(LineSeg.new(p(0,0), p(2,0)))
    canon.add(LineSeg.new(p(1,1), p(1,0)))
    assert_equal(3, canon.line_segs.size)
    expect(canon, expected_segs2)
    
    # old/1: old segment has its point 1 along the other segment.
    canon = CanonicalLineSegList.new
    canon.add(LineSeg.new(p(1,0), p(1,1)))
    canon.add(LineSeg.new(p(0,0), p(2,0)))
    assert_equal(3, canon.line_segs.size)
    expect(canon, expected_segs1)


    # old/2: old segment has its point 2 along the other segment.
    canon = CanonicalLineSegList.new
    canon.add(LineSeg.new(p(1,1), p(1,0)))
    canon.add(LineSeg.new(p(0,0), p(2,0)))
    assert_equal(3, canon.line_segs.size)
    expect(canon, expected_segs2)


  end


  def test_add_endpoint_terminus

    # Add a seg, then one that intersects only at a segment endpoint.
    # (1, 1): First point of pt1, first point of pt2
    canon = CanonicalLineSegList.new
    canon.add(ls0001 = LineSeg.new(p(0,0), p(0,1)))
    canon.add(ls0011 = LineSeg.new(p(0,0), p(1,1)))
    assert_equal( 2, canon.line_segs.size)
    expect(canon, [ls0001, ls0011])
    
    # (1, 2)
    canon = CanonicalLineSegList.new
    canon.add(ls0001 = LineSeg.new(p(0,0), p(0,1)))
    canon.add(ls1100 = LineSeg.new(p(1,1), p(0,0)))
    assert_equal( 2, canon.line_segs.size)
    expect(canon, [ls0001, ls1100])
    
    # (2, 1)
    canon = CanonicalLineSegList.new
    canon.add(ls0001 = LineSeg.new(p(0,0), p(0,1)))
    canon.add(ls0111 = LineSeg.new(p(0,1), p(1,1)))
    assert_equal( 2, canon.line_segs.size)
    expect(canon, [ls0001, ls0111])
    
    # (2, 2)
    canon = CanonicalLineSegList.new
    canon.add(ls0001 = LineSeg.new(p(0,0), p(0,1)))
    canon.add(ls1101 = LineSeg.new(p(1,1), p(0,1)))
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
    assert_equal(LineSeg.new(P00, P11).rect.to_s, Rectangle.new(0, 0, 2, 2).to_s)
    assert_equal(LineSeg.new(P11, P00).rect.to_s, Rectangle.new(0, 0, 2, 2).to_s)

    assert_equal(LineSeg.new(P01, P10).rect.to_s, Rectangle.new(0, 0, 2, 2).to_s)
    assert_equal(LineSeg.new(P10, P01).rect.to_s, Rectangle.new(0, 0, 2, 2).to_s)


    assert_equal(LineSeg.new(P00, P22).rect.to_s, Rectangle.new(0, 0, 3, 3).to_s)
    assert_equal(LineSeg.new(P22, P00).rect.to_s, Rectangle.new(0, 0, 3, 3).to_s)


    assert_equal(LineSeg.new(P00, P01).rect.to_s, Rectangle.new(0, 0, 1, 2).to_s)
    assert_equal(LineSeg.new(P00, P10).rect.to_s, Rectangle.new(0, 0, 2, 1).to_s)

  end

  def test_equal
    assert(LineSeg.new(P00, P11) == LineSeg.new(P00, P11))

    assert(LineSeg.new(P00, P11) == LineSeg.new(P00, P11))

    assert(LineSeg.new(P00, P11) != LineSeg.new(P11, P22))
    assert(!(LineSeg.new(P00, P11) == LineSeg.new(P11, P22)))
  end

  def test_rect_overlaps
    assert(LineSeg.new(P00, P11).rect_overlaps?(LineSeg.new(P00, P11)))
    assert(LineSeg.new(P00, P11).rect_overlaps?(LineSeg.new(P11, P00)))
    assert(LineSeg.new(P00, P22).rect_overlaps?(LineSeg.new(P00, P11)))
    assert(LineSeg.new(P00, P11).rect_overlaps?(LineSeg.new(P00, P22)))
    
    assert_false(LineSeg.new(P00, P01).rect_overlaps?(LineSeg.new(P11, P22)))
    assert_false(LineSeg.new(P11, P22).rect_overlaps?(LineSeg.new(P00, P01)))

    assert(LineSeg.new(P00, P11).rect_overlaps?(LineSeg.new(P11, P22)))
    assert(LineSeg.new(P22, P11).rect_overlaps?(LineSeg.new(P11, P00)))

    # Cases where overlap, but no intersect.
    assert(LineSeg.new(P00, P33).rect_overlaps?(LineSeg.new(P21, P20)))
    assert(LineSeg.new(P00, P33).rect_overlaps?(LineSeg.new(P12, P02)))
    assert(LineSeg.new(P00, P33).rect_overlaps?(LineSeg.new(P02, P12)))
    
  end

  def test_intersect
    # Don't overlap
    assert_nil(LineSeg.new(P00, P01).intersection(LineSeg.new(P11, P22)))

    # Parallel
    assert_nil(LineSeg.new(P00, P10).intersection(LineSeg.new(P01, P11)))
    assert_nil(LineSeg.new(P00, P01).intersection(LineSeg.new(P10, P12)))

    # Intersections
    assert_equal(LineSeg.new(P00, P22).intersection(LineSeg.new(P10, P12)).to_s, Point.new(1, 1).to_s)
    
    # This one should fail, as while the rects overlap, there's no
    # intersection in the segments themselves.
    assert_nil(LineSeg.new(P00, P33).intersection(LineSeg.new(P21, P20)))
    assert_nil(LineSeg.new(P00, P33).intersection(LineSeg.new(P12, P02)))
    assert_nil(LineSeg.new(P00, P33).intersection(LineSeg.new(P02, P12)))
    
    # And one that hits 1/3 and 2/3 between points
    ls1 = LineSeg.new(P00, P32)
    assert_equal(ls1.intersection(LineSeg.new(P10, P11)), P11)
    assert_equal(ls1.intersection(LineSeg.new(P21, P22)).to_s, P21.to_s)

  end

end
