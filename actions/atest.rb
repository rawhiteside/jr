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
      {:type => :point, :label => 'Drag top left corner of patch', :name => 'tl'},
      {:type => :point, :label => 'Drag lower right corner of patch', :name => 'lr'},
      {:type => :text, :label => 'Name of patch (one word)', :name => 'name'}
    ]
    @vals = UserIO.prompt(parent, nil, 'Define patch', gadgets)

  end


  def act
    x = @vals['tl.x'].to_i
    y = @vals['tl.y'].to_i
    width = @vals['lr.x'].to_i - x
    height = @vals['lr.y'].to_i - y
    rect = Rectangle.new(x, y, width, height)
    pb = PixelBlock.new(rect)
    filename = "patches/#{@vals['name']}.png"
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



class TimeTest < Action

  def initialize(name = 'Time something (change code for target)')
    super(name, 'Test/Dev')
  end

  def setup(parent)
    true
  end

  def act

    rect = nil
    num_times = 100
    elapsed = nil
    
    elapsed = Timer.time_this do
      num_times.times do
        rect = WindowGeom.rectFromPoint(Point.new(50, 50))
        if rect.nil?
          puts "failed"
          break
        end
      end

    end
    once = elapsed / num_times
    puts "Num_times = #{num_times}, total = #{elapsed}, once = #{once}"
  end
end


Action.add_action(TimeTest.new)
