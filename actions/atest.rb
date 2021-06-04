require 'action'
require 'timer'
require 'window'
require 'actions/kettles'

class DefinePatchTest < Action

  def initialize(name = 'Define screen patch')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    gadgets = [
      {:type => :label, :label => 'Define a screen rectangle to capture.'},
      {:type => :point, :label => 'Drag Top Left of rect', :name => 'tl'},
      {:type => :point, :label => 'Drag Bottom Right of rect', :name => 'br'},
      {:type => :text, :label => 'Name of image (one word)', :name => 'name', :size => 12}
    ]
    @vals = UserIO.prompt(parent, nil, 'Define subimage', gadgets)

  end


  def act
    tl = point_from_hash(@vals, 'tl')
    br = point_from_hash(@vals, 'br')

    rect = Rectangle.new(tl.x, tl.y, (br.x - tl.x), (br.y - tl.y))
    pb = PixelBlock.new(rect)
    filename = "images/#{@vals['name']}.png"
    pb.save_image(filename)
    pb_new = PixelBlock.load_image(filename)
    UserIO.show_image(pb_new, "Image read back.")
  end

end

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
    cl = ClockLocWindow.instance
    pb = PixelBlock.new(cl.rect)
    pb.save_image(filename)
  end

end
Action.add_action(CaptureCLBackground.new)

class PinnableGeomTest < Action

  def initialize(name = 'Test PinnableWindowGeom')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Drag to window', :name => 'pt'},
    ]
    @vals = UserIO.prompt(parent, nil, 'Show me the window', gadgets)
  end


  def act
    pt = point_from_hash(@vals, 'pt')
    win = PinnableWindow.fromPoint(pt)
    puts win
    puts win.to_s
    p win
    puts win.rect
    puts win.rect.to_s
    p win.rect
  end
end
Action.add_action(PinnableGeomTest.new)


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

class ReduceTest < Action
  def initialize(name = 'Reduce Image')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    true
  end


  def act
    pb = full_screen_capture
    r2 = ImageUtils.resize(pb.buffered_image, 2)
    UserIO.show_image(r2, "Factor 2")
    r3 = ImageUtils.resize(pb.buffered_image, 3)
    UserIO.show_image(r3, "Factor 3")
    r4 = ImageUtils.resize(pb.buffered_image, 4)
    UserIO.show_image(r4, "Factor 4")
  end  
end

Action.add_action(ReduceTest.new)

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

class CoordWatcher < Action
  def initialize
    super('Watch Coords', 'Test/Dev')
  end
  
  def setup(parent)
    true
  end

  def act
    win = ClockLocWindow.instance
    loop do
      coords = win.coords
      if coords.nil?
        send_vk VK_ESCAPE
        beep
        return
      else
        # puts coords.to_a
      end
      sleep 0.5
    end
  end
end
Action.add_action(CoordWatcher.new)
