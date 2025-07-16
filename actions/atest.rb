require 'action'
require 'timer'
require 'image_utils'
require 'window'
require 'actions/kettles'

class PatchStats < Action
  def initialize(name = "Stats for patch")
    super(name, 'Test/Dev')
    @pt = nil
  end

  def setup(parent)
    gadgets = [
      
      {:type => :point, :label => 'Drag Top Left of rect', :name => 'origin'},
      {:type => :number, :label => 'How many rows?', :name => 'rows'},
      {:type => :number, :label => 'How many columns?', :name => 'cols'},
      {:type => :number, :label => 'Widen range increment?', :name => 'widen'},
      {:type => :checkbox, :label => "HSB? (Else RGB)", :name => 'hsb?'},
      {:type => :checkbox, :label => "Add to existing range?", :name => 'add_patch?'},
      {:type => :text, :label => 'Ranges:', :name => 'ranges', :size => 30},
      {:type => :button, :label => 'Get ranges',
       :action => Proc.new {|data_gets, data_puts| gather_ranges(data_gets, data_puts)},
      },
      
      {:type => :label, :label => "Patch detect."},
      {:type => :number, :label => 'Match size', :name => 'match_size'},
      {:type => :button, :label => 'Show results (Update DB first)', 
       :action => Proc.new {|data_gets, data_puts| show_matches(data_gets, data_puts)}},

      {:type => :text, :label => 'DB entry name:', :name => 'db_entry_name'},
      {:type => :button, :label => 'Update patch db', 
       :action => Proc.new {|data_gets, data_puts| update_db(data_gets, data_puts)},
      }
    ]
    @vals = UserIO.prompt(parent, name, 'Define patch', gadgets)
  end

  def update_db(data_gets, data_puts)
    name = data_gets['db_entry_name'].call
    is_hsb = (data_gets['hsb?'].call == "true")
    ranges = eval(data_gets['ranges'].call)
    match_size = data_gets['match_size'].call.to_i
    
    rm = RangeMatch.new
    rm.update_ranges(name, is_hsb, match_size, ranges)
    rm.save_color_ranges
  end

  def gather_ranges(data_gets, data_puts)
    stats_point = Point.new(data_gets['origin.x'].call.to_i,
                            data_gets['origin.y'].call.to_i)
    height = data_gets['rows'].call.to_i
    width = data_gets['cols'].call.to_i
    widen = data_gets['widen'].call.to_i
    patch = PixelBlock.new(Rectangle.new(stats_point.x, stats_point.y, width, height))
    new_ranges = []
    if data_gets['hsb?'].call == 'true'
      new_ranges = patch_color_ranges_hsb(patch)
    else
      new_ranges = patch_color_ranges_rgb(patch)
    end

    new_ranges = widen_range(new_ranges, widen) if widen > 0

    if data_gets['add_patch?'].call == 'false'
      data_puts['ranges'].call(new_ranges.to_s)
    else
      # Add this range to the existing one.
      curr_ranges = data_gets['ranges'].call
      if (!curr_ranges.nil? && curr_ranges != '')
        curr_ranges = eval(curr_ranges)
        3.times do |i|
          new_ranges[i] =
            [new_ranges[i].first, curr_ranges[i].first].min..[new_ranges[i].last, curr_ranges[i].last].max
        end
      end
      data_puts['ranges'].call(new_ranges.to_s)
    end
  end

  def show_matches(data_gets, data_puts)
    ranges = eval(data_gets['ranges'].call)
    match_size = data_gets['match_size'].call.to_i
    is_hsb = data_gets['hsb?'].call == 'true'
    name = data_gets['db_entry_name'].call
    rm = RangeMatch.new
    @pt = rm.click_point(name, false, true)
  end

  def act
    mm @pt if @pt
  end
    
  def widen_range(r, wide)
    [
      (r[0].first - wide)..(r[0].last + wide), 
      (r[1].first - wide)..(r[1].last + wide), 
      (r[2].first - wide)..(r[2].last + wide),
    ]
  end


  def color_volume(cvec)
    Math.sqrt((cvec[0].last - cvec[0].first + 1)**2 +
              (cvec[1].last - cvec[1].first + 1)**2 +
              (cvec[2].last - cvec[2].first + 1)**2)
  end
  
  def patch_color_ranges_hsb(pb)
    hmin = smin = bmin = 255
    hmax = smax = bmax = 0
    0.upto(pb.width-1) do |x|
      0.upto(pb.height-1) do |y|
        c = pb.get_color(x, y)
        hsb = Color.RGBtoHSB(c.red, c.green, c.blue, nil)

        hmin = [255*hsb[0], hmin].min.to_i
        hmax = [255*hsb[0], hmax].max.to_i

        smin = [255*hsb[1], smin].min.to_i
        smax = [255*hsb[1], smax].max.to_i

        bmin = [255*hsb[2], bmin].min.to_i
        bmax = [255*hsb[2], bmax].max.to_i
      end
    end
    return [hmin..hmax, smin..smax, bmin..bmax]
      
  end
  def patch_color_ranges_rgb(pb)
    rmin = gmin = bmin = 255
    rmax = gmax = bmax = 0
    0.upto(pb.width-1) do |x|
      0.upto(pb.height-1) do |y|
        color = pb.get_color(x, y)
        rmin = [color.red, rmin].min
        rmax = [color.red, rmax].max

        gmin = [color.green, gmin].min
        gmax = [color.green, gmax].max

        bmin = [color.blue, bmin].min
        bmax = [color.blue, bmax].max
      end
    end
    return [rmin..rmax, gmin..gmax, bmin..bmax]
      
  end
                        
end
Action.add_action(PatchStats.new)


class StaticPixelsTest < Action

  def initialize(name = 'Static pixels in patch')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    gadgets = [
      {:type => :label, :label => 'Define a screen rectangle to watch.'},
      {:type => :point, :label => 'Drag Top Left of rect', :name => 'tl'},
      {:type => :point, :label => 'Drag Bottom Right of rect', :name => 'br'},
      {:type => :number, :label => 'Seconds to watch', :name => 'seconds'},
      {:type => :text, :label => 'Name of image (one word)', :name => 'name', :size => 12}
    ]
    @vals = UserIO.prompt(parent, name, 'Define subimage', gadgets)

  end


  def act
    tl = point_from_hash(@vals, 'tl')
    br = point_from_hash(@vals, 'br')
    secs = @vals['seconds'].to_i
    start_time = Time.now

    rect = Rectangle.new(tl.x, tl.y, (br.x - tl.x), (br.y - tl.y))
    pb_first = PixelBlock.new(rect)
    loop do
      pb = PixelBlock.new(rect)
      clear_changed_pixels(pb_first, pb, 0xffffff)
      sleep 0.05
      break if (Time.now - start_time) > secs
    end

    filename = "images/#{@vals['name']}.png"
    pb_first.save_image(filename)
    pb_new = PixelBlock.load_image(filename)
    UserIO.show_image(pb_new, "Image read back.")
    UserIO.info("Done!")
  end

  # Look for pixels that differ between the two pb's.  If they're
  # different, set the pb_ref pixel to +pixel+.
  def clear_changed_pixels(pb_ref, pb, pixel)
    pb.width.times do |x|
      pb.height.times do |y|
        pb_ref.set_pixel(x, y, pixel) if pb_ref.get_pixel(x, y) != pb.get_pixel(x, y)
      end
    end
  end

end
Action.add_action(StaticPixelsTest.new)

class CaptureCLBackground < Action

  def initialize(name = 'Capture ClockLoc background')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    gadgets = [
      {:type => :text, :label => 'Name of image (one word)', :name => 'name', :size => 12}
    ]
    @vals = UserIO.prompt(parent, persistence_name, 'Capture ClockLoc background image', gadgets)

  end

  def act
    filename = "images/#{@vals['name']}.png"
    puts filename
    cl = ClockLocWindow.new
    pb = PixelBlock.new(cl.rect)
    pb.save_image(filename)
  end

end
Action.add_action(CaptureCLBackground.new)


class FindExactTest < Action

  def initialize(name = 'Find Exact Template')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    gadgets = [
      {:type => :text, :label => 'Name of template (one word)', :name => 'name'}
    ]
    @vals = UserIO.prompt(parent, name, 'Template image to find', gadgets)
  end


  def act
    filename = "images/#{@vals['name']}.png"
    template = PixelBlock.load_image(filename)
    pb_full = PixelBlock.full_screen
    pt = pb_full.find_template_exact(template)
    mm(pt) if pt
  end
end
Action.add_action(FindExactTest.new)


class FindBest < Action

  def initialize(name = 'Find best Template')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    gadgets = [
      {:type => :text, :label => 'Name of template (one word)', :name => 'name'},
      {:type => :number, :label => 'threshold', :name => 'thresh'},
    ]
    @vals = UserIO.prompt(parent, name, 'Template image to find', gadgets)
  end


  def act
    filename = "images/#{@vals['name']}.png"
    threshold = @vals['thresh'].to_i
    template = PixelBlock.load_image(filename)
    pb_full = PixelBlock.full_screen
    pt = pb_full.find_template_best(template, threshold)
    mm(pt) if pt
  end
end
Action.add_action(FindBest.new)

class MouseWheelTest < Action
  def initialize(name = 'Use the mouse wheel')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    true
  end


  def act
    sleep 1
    mouse_wheel(5)
    sleep 1
    mouse_wheel(-3)
  end  
end
Action.add_action(MouseWheelTest.new)

class TimeTest < Action

  def initialize(name = 'Time something')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    true
  end

  def act

    rect = nil
    num_times = 1000
    elapsed = nil
    rect = Rectangle.new(10, 10, 100, 100)
    elapsed = Timer.time_this do
      pb = PixelBlock.new(rect)
    end
    once = elapsed / num_times
    puts "Num_times = #{num_times}, total = #{elapsed}, once = #{once}"
  end
end


Action.add_action(TimeTest.new)

