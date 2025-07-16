# Returns a Point.
# +which+ is the name of the thing to be clicked:
# Chariot, Apiariy, or Silt, for example.

class RangeMatch
  @@range_file = "color_ranges.yaml"

  # +which+ is the name of the thing to be clicked:
  # Chariot, Apiariy, or Silt, for example.
  def initialize(which, is_fullscreen = false)
    @ranges = load_color_ranges
    @which = which

    # target_info:
    # {:is_hsb => bool, :match_size => n, :ranges => [[r..r, g..g, b..b]}
    @target_info = @ranges[which]
    @is_fullscreen =  is_fullscreen
  end

  def click_point(is_show_images = false)
    return nil unless @target_info
    pb = capture_pb(@is_fullscreen)
    pb = to_HSB(pb) if @target_info[:is_hsb]

    UserIO.show_image(pb, "Original") if is_show_images

    # Now, fill a pb with single-pixel matches
    ranges = @target_info[:ranges]
    pb_match = mark_matching_pixels(pb, ranges, 1)
    UserIO.show_image(pb_match, "Single matches") if is_show_images
    match_size = @target_info[:match_size]
    pb_match = mark_match_size(pb, ranges, match_size) if match_size > 1
    UserIO.show_image(pb_match, "After match_size") if is_show_images
    
    return find_click_point(pb_match, match_size)
  end

  # Find the click point closest to the toon.
  def find_click_point(pb, match_size)
    best_dist = 10000
    best_pt = nil
    # Measured full-screen.
    toon_point = pb.from_screen(Point.new(960, 550))
    # Find the click point closest to the toon.
    (pb.rect.width - match_size).times do |x|
      (pb.rect.height - match_size).times do |y|
        if pb.get_pixel(x, y) == 0xFFFFFF
          tp = toon_point.distance_sq(Point.new(x, y))
          if best_pt.nil? || tp < best_dist
            best_dist = tp
            best_pt = Point.new(x, y)
          end
        end
      end
    end
    off = ((match_size + 1)/2).to_i
    if best_pt
      return pb.to_screen(Point.new(best_pt.x + off, best_pt.y + off))
    else
      return nil
    end

  end

  # pb is marked 1/0 for single-pixel matches.
  # Now, UL point of squares of size match_size that are in ranges. 
  def mark_match_size(pb, ranges, match_size)
    return pb if match_size < 2
    
    pb_match = PixelBlock.constructBlank(pb.rect, 0x000000)
    (pb.rect.width - match_size).times do |x|
      (pb.rect.height - match_size).times do |y|
        is_match = true
        match_size.times do |xoff|
          match_size.times do |yoff|
            if !pixel_match_ranges?(pb.get_pixel(x + xoff, y + yoff), ranges)
              is_match = false
              break
            end
          end
          break unless is_match
        end
        if is_match
          pb_match.set_pixel(x, y, 0xFFFFFF)
        else
          pb_match.set_pixel(x, y, 0x000000)
        end
      end
    end

    return pb_match
  end

  def pixel_match_ranges?(pix, ranges)
    c = Color.new(pix)
    vals = [c.red, c.green, c.blue]
    ranges.each do |r|
      return nil unless r.include?(vals.shift)
    end

    return true
  end

  # Mark each pixel with 0xFFFFFF if it matches the ranges. 0x000000
  # otherwise.
  def mark_matching_pixels(pb, c_ranges, match_size)
    pb_match = PixelBlock.constructBlank(pb.rect, 0x000000)

    pb.rect.width.times do |x|
      pb.rect.height.times do |y|
        if color_matches_ranges?(pb.get_color(x, y), c_ranges)
          pb_match.set_pixel(x, y, 0xFFFFFF)
        else
          pb_match.set_pixel(x, y, 0x000000)
        end
      end
    end

    return pb_match
  end
  
  def color_matches_ranges?(c, ranges)
    vals = [c.red, c.green, c.blue]
    ranges.each do |r|
      return nil unless r.include?(vals.shift)
    end

    return true
  end

  def update_ranges(which, is_hsb, match_size, ranges)
    @ranges[which] =  {:is_hsb => is_hsb, :match_size => match_size, :ranges => ranges}
    save_color_ranges
    # incase our target got updated. 
    @info = @ranges[@which]
  end

  def save_color_ranges
    File.open(@@range_file, 'w') {|f| YAML.dump(@ranges, f)}
  end

  # Hash: {:is_hsb => bool, :ranges => []}
  def load_color_ranges
    name_map = {}
    name_map = YAML.load_file(@@range_file) if File.exist?(@@range_file)
    name_map
  end

  def capture_pb(is_fullscreen)
    if is_fullscreen
      return ARobot.shared_instance.full_screen_capture
    else
      dim = ARobot.shared_instance.screen_size
      h3 = (dim.height/3).to_i
      w3 = (dim.width/3).to_i
      rect = Rectangle.new(w3, h3, w3, h3)
      return PixelBlock.new(rect)
    end
    
  end

end


# What crop is this for? 
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
