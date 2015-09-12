require 'java'

import org.foa.PixelBlock

# Grab/watch a block of pixels.
class PixelBlockWatcher < ARobot
  # Give x, y near the center of the block you want to watch.
  # Later, call each_delta to get the pixel changes.
  def initialize(x, y, width, height, stride = 1)
    super()
    @x_origin = [0, x - width/2].max
    @y_origin = [0, y - height/2].max
    @width = width
    @height = height

    @pb_start = screen_rectangle(@x_origin, @y_origin, @width, @height)
  end

  # Find a pixel that's changed and that's surrounded by changed pixels.
  # - Pixels on the edge of objects that *appear* as part of the 
  #   object are not always clickable.  This finds something that's more
  #   likely clickable.
  def find_surrounded_green_change(threshold = 50)
    # put the changed pixels into a handy hash.
    changed = Hash.new(0)

    # Find pixels that changed and became more green
    each_delta do |x, y, dr, dg, db|
      v = dg - dr - db
      # v = dr.abs + dg.abs + db.abs
      if v > threshold && dg > dr && dg > db
	changed[[x, y]] = 1
      end
    end

    # Build a new array with each element having the sum of
    # its neighbors.
    sum = changed.dup
    sum.each_key do |k|
      x = k[0]
      y = k[1]
      -1.upto(1) {|i| -1.upto(1) {|j| sum[k] += changed[[i+x, j+y]]}}
    end

    # Now, return the first coordinate with the max count
    xy = []
    max = -1
    sum.each_key do |k|
      if sum[k] > max
	max = sum[k]
	xy = k
      end
    end

    return xy
  end

  def get_pixel_block
    screen_rectangle(@x_origin, @y_origin, @width, @height)
  end

  # Yields to the block with x, y, dr, dg, db
  # x, y are pixel coords.
  # delta-red, delta-green, delta-blue
  def each_delta
    current = get_pixel_block
    @width.times do |ix|
      @height.times do |iy|
	color = @pb_start.color(ix, iy)
	r1, g1, b1 = color.red, color.green, color.blue
	color = current.color(ix, iy)
	r2, g2, b2 = color.red, color.green, color.blue
	x, y = @pb_start.to_screen(ix, iy)
	yield x, y, r2-r1, g2-g1, b2-b1
      end
    end
  end
end
