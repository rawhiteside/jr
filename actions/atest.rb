require 'action'
require 'timer'
require 'window'
require 'actions/kettles'

class DefinePatchTest < Action

  def initialize(name = 'Define patch')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    gadgets = [
      {:type => :label, :label => 'Define a screen rectangle to capture.'},
      {:type => :point, :label => 'Drag center of rect', :name => 'center'},
      {:type => :number, :label => 'Width', :name => 'width'},
      {:type => :number, :label => 'Height', :name => 'height'},
      {:type => :text, :label => 'Name of patch (one word)', :name => 'name', :size => 12}
    ]
    @vals = UserIO.prompt(parent, nil, 'Define patch', gadgets)

  end


  def act
    x = @vals['center.x'].to_i
    y = @vals['center.y'].to_i
    width = @vals['width'].to_i
    height = @vals['height'].to_i
    rect = Rectangle.new(x - width/2, y - height/2, width, height)
    pb = PixelBlock.new(rect)
    filename = "images/#{@vals['name']}.png"
    pb.save_image(filename)
    pb_new = PixelBlock.load_image(filename)
    UserIO.show_image(pb_new, "Image read back.")
  end

end

Action.add_action(DefinePatchTest.new)

class FindPatchTest < Action

  def initialize(name = 'Find patch')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    gadgets = [
      {:type => :text, :label => 'Name of patch (one word)', :name => 'name'}
    ]
    @vals = UserIO.prompt(parent, nil, 'Patch to find', gadgets)
  end


  def act
    filename = "images/#{@vals['name']}.png"
    pb_patch = PixelBlock.load_image(filename)
    pb_full = full_screen_capture
    puts "finding"
    pt = pb_full.find_patch(pb_patch)
    p pt.to_s
    mm(pt)
  end
end

Action.add_action(FindPatchTest.new)

class FindExactTest < Action

  def initialize(name = 'Find Exact Template')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    gadgets = [
      {:type => :text, :label => 'Name of patch (one word)', :name => 'name'}
    ]
    @vals = UserIO.prompt(parent, nil, 'Patch to find', gadgets)
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

  def initialize(name = 'Time something (change code for target)')
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
