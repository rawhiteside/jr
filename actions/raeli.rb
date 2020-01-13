require 'action'
import javax.imageio.ImageIO

class Raeli < Action
  def initialize
    super('Raeli', 'Buildings')
  end

  def setup(parent)
    comps = [
      {:type => :point, :label => 'Drag to pinned Raeli', :name => 'w'},
      {:type => :combo, :label => "Task", :name => 'task', :vals => ['Watch', 'Burn and watch'], },
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, comps)
  end

  def act
    w = PinnableWindow.from_point(point_from_hash(@vals, 'w'))
    return unless w

    start = Time.now
    w.click_on('Begin') if @vals['task'] =~ /Burn/

    black_count_prev = -1

    loop do
        w.refresh

        pb = PixelBlock.new(w.rect)
        black_count = count_black(pb)

        if black_count != black_count_prev
          black_count_prev = black_count
          minutes = (Time.now - start).to_i/60
          filename = "raeli-shots/image.%d.png" % [minutes]
          ImageIO.write(pb.buffered_image, 'png', java.io.File.new(filename))
        end
    end

    sleep(10)
    check_for_pause
  end

  def count_black(pb)
    count = 0
    pb.width.times do |x|
      pb.height.times do |y|
        if pb.color(x, y) == Color.black
          count += 1
        end
      end
    end
    return count
  end



end

Action.add_action(Raeli.new)
