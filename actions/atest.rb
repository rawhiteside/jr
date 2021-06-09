require 'action'
require 'timer'
require 'window'
require 'actions/kettles'

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

class HowMuchTest < Action

  def initialize(name = 'Test HowMuch')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    true
  end

  def act
    check_for_pause
    HowMuch.amount(2)
  end
end
Action.add_action(HowMuchTest.new)


class FindExactTest < Action

  def initialize(name = 'Find Exact Template')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    gadgets = [
      {:type => :text, :label => 'Name of template (one word)', :name => 'name'}
    ]
    @vals = UserIO.prompt(parent, nil, 'Template image to find', gadgets)
  end


  def act
    filename = "images/#{@vals['name']}.png"
    template = PixelBlock.load_image(filename)
    pb_full = full_screen_capture
    pt = pb_full.find_template_exact(template)
    mm(pt) if pt
  end
end
Action.add_action(FindExactTest.new)

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

