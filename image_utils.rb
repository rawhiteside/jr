class CropDetector

 def initialize(center, offset, stride)
   @coords = get_coords(center, offset, stride)
   @orig_pixels = []
   coords.each {|xy| @orig_pixels << get_pixel(xy[0], xy[1])}
 end

 def find_crop
   hue_diffs = []
   orig = @orig_pixels.dup
   # Compute the hue chage in each pixel.
   coords.each do |xy|
     pixel << get_pixel(xy[0], xy[1])
     # compute the change
     diff = pixel ^ orig.shift
     hue_diffs << hsl_from_pixel(diff)
   end

   ind = hue_diffs.index(hue_diffs.max)
   return @coords[ind]
 end

 def get_coords(center, offset, stride)
   count = 1 + 2 * offset
   start_x = center[0]- offset * stride
   start_y = center[1]- offset * stride

   coords = []

   y = start_y
   count.times do |irow|
     x = start_x
     count.times do |icol|
       x += stride
       coords << [x, y]
     end
   end

   return coords
 end

end
