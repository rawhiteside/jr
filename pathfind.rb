require 'java'
import java.awt.Point

class PathFinder
  # Returns a sequence of points 
  def find_path_to(destination)
    
  end
end

class CanonicalLineSegList

  def initialize
    @segs = []
  end

  def to_s
    str = '['
    @segs.each {|seg| str << " [ #{seg.pt1.to_s}, #{seg.pt2.to_s} ], "}
    str << ']'
  end

  # Add the new segement.  This can result in +new_seg+ being split
  # into possibly many segements.  Onw of these will be processed and
  # added to +@segs+.  The remaing split-out segements will be
  # returned, so you can call this method again with those.
  def process_and_add(new_seg)

    # If this is a duplicate, just don't add it.
    return nil if duplicate?(new_seg)


    # Seek and handle intersections.
    new_list = []
    reprocess = []
    @segs.each do |seg|
      pt_intersect = seg.intersection(new_seg)
      unless pt_intersect
        new_list << seg
        next
      end

      # No splits if they just intersect at terminii.  
      next if terminus_terminus_intersect(pt_intersect, new_list, seg, new_seg)
      # Separate handing of intersection at a terminus
      if rv = terminus_line_intersect(pt_intersect, new_list, seg, new_seg)
        if rv.size > 1
          new_seg = rv.shift
          reprocess << rv
        end
      else
        # Must be a line/line intersect.
        rv = line_line_intersect(pt_intersect, new_list, seg, new_seg)
        new_seg = rv.shift
        reprocess << rv
      end
      
    end
    new_list << new_seg
    @segs = new_list

    if reprocess.size == 0
      return nil
    else
      return reprocess.flatten
    end
  end

  # If this is a terminus/terminus intersect, then handle it by just
  # adding seg. If not such an intersect, return false.
  def terminus_terminus_intersect(pt_intersect, new_list, seg, new_seg)
    if (new_seg.pt1 == pt_intersect || new_seg.pt2 == pt_intersect) && 
       (seg.pt1 == pt_intersect || seg.pt2 == pt_intersect)
      new_list << seg
      return true
    end
    return false
  end

  # If this is a terminus/line intersect, then add appropriate newly
  # created segs, and return a possible modified version of new_seg.
  # Return nil if it's not such an intersect.
  def terminus_line_intersect(pt_intersect, new_list, seg, new_seg)

    # Is the intersect at one of +new_seg+ terminii?
    # If so, split +seg+ into two segs at pt_intersect.
    if pt_intersect == new_seg.pt1 || pt_intersect == new_seg.pt2
      new_list << LineSeg.new(seg.pt1, pt_intersect)
      new_list << LineSeg.new(pt_intersect, seg.pt2)
      return []
    end

    # Does a +seg+ terminus lie along *new_seg+?
    #
    # If so, add +seg+ to the +new_list+ and return the two part of the slit +new_seg+
    if pt_intersect == seg.pt1 || pt_intersect == seg.pt2
      new_list << seg
      return [LineSeg.new(new_seg.pt1, pt_intersect), LineSeg.new(pt_intersect, new_seg.pt2)]
    end

    return nil
  end

  # This is a line/line intersect.  Split the two segments, add "old"
  # ones to new_list, and return the parts of +new_seg+ as value.
  # Return nil if it's not such an intersect.
  # 
  def line_line_intersect(pt_intersect, new_list, seg, new_seg)

    new_list << LineSeg.new(seg.pt1, pt_intersect)
    new_list << LineSeg.new(pt_intersect, seg.pt2)

    return [LineSeg.new(new_seg.pt1, pt_intersect), LineSeg.new(pt_intersect, new_seg.pt2)]

  end

  def add(add_me)
    if @segs.size == 0
      @segs << add_me
    else
      # Adding new_seg may result in its being split into many parts.
      # One of these will get added to @segs, but the remainder will
      # be returned, and must me individually processed.  This all
      # seems surprisingly complicated.  I suspect I'm missing
      # something.
      to_process = [add_me]
      while to_process.size > 0
        more_to_add = []
        to_process.each do |new_seg|
          more = process_and_add(new_seg)
          more_to_add << more if more
        end
        to_process = more_to_add.flatten
      end
    end
  end

  # Is this segment a duplicate of an already-added one?
  def duplicate?(new_seg)
    @segs.each do |seg|
      return true if new_seg == seg
    end
    false
  end

  def line_segs
    @segs
  end
end


# https://www.topcoder.com/thrive/articles/Geometry%20Concepts%20part%202:%20%20Line%20Intersection%20and%20its%20Applications
# 
# We're given two points of the line segment.  Get the equation for
# the corresponding line in the form:
# 
# Ax + By = C
#
# Compute A, C, and C from the following:
#
# A = y2 - y1
# B = x1 - x2
# C = A * x1 + B * y1
#
class LineSeg
  attr_reader :pt1, :pt2, :rect, :a, :b, :c

  def initialize(pt1, pt2)
    
    @pt1 = Point.new(pt1)
    @pt2 = Point.new(pt2)
    # Used in computing intersections. 
    @a = @pt2.y - @pt1.y
    @b = @pt1.x - @pt2.x
    @c = @a * @pt1.x + @b * @pt1.y
    # Used in determining overlaps.
    @rect = Rectangle.new([@pt1.x, @pt2.x].min, [@pt1.y, @pt2.y].min,
                          (@pt1.x - @pt2.x).abs + 1, (@pt1.y - @pt2.y).abs + 1)
  end
  
  def ==(other)
    self.pt1 == other.pt1 && self.pt2 == other.pt2
  end

  def rect_overlaps?(other)
    rect.intersects(other.rect)
  end

  # Return the Point at which other intersects self, or nil.
  def intersection(other)
    # If rects don't overlap, then the line segments can't intersect.
    # Note that this handles the paralle case, as well as the case
    # where the intersection is outside the line segments.
    return nil unless rect_overlaps?(other)
    det = @a * other.b - other.a * @b
    # Shouldn't happen, but just in case.
    # Note:  Everyting's an integer so far.
    return nil if det == 0

    x_float = (other.b * @c - @b * other.c).to_f / det.to_f
    y_float = (@a * other.c - other.a * @c).to_f / det.to_f
    
    intersect = Point.new(x_float.round, y_float.round)
    if rect.contains(intersect) && other.rect.contains(intersect)
      return intersect
    else
      return nil
    end
  end
  def to_s
    "LineSeg: (#{@pt1.x},#{@pt1.y})->(#{@pt2.x},#{@pt2.y})"
  end
end

class SegsForName
  def initialize
    @hash = Hash.new([])
  end

  def add(seg)
    val = @hash[seg.name1] << seg
    @hash[seg.name1] = val
  end

  def get(name)
    @hash[name]
  end
end

# LineSeg with names for the two ponts.
class NamedLineSeg < LineSeg
  attr_reader :name1, :name2
  def initialize(pt1, pt2, name1 = nil, name2 = nil)
    super(pt1, pt2)
    @name1 = (name1.nil?) ? pt1 : name1
    @name2 = (name2.nil?) ? pt2 : name2
  end
end
