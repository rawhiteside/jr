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

    prev_color = nil
    counter = 0
    loop do
      px = w.rect.x + 30
      py = w.rect.y + 200
      color = get_color(px, py)
      if color != prev_color

        counter += 1

        w.refresh
        prev_color = color
        hsb = Color.RGBtoHSB(color.red, color.green, color.blue, nil)
        hsb_str = sprintf("%0.3f, %0.3f, %0.3f", hsb[0], hsb[1], hsb[2])

        File.open('Raeli.log', 'a') do |f|
	  f.puts("#{counter}, #{Time.now}, minutes:=> , #{(Time.now - start).to_i/60}, RGB:=>, #{color.red}, #{color.green}, #{color.blue}, HSB:=>, #{hsb_str}")
        end
        filename = "raeli-shots/image.%04d.%03d.%03d.%03d.png" % [counter, color.red, color.green, color.blue]
        pb = PixelBlock.new(w.rect)
        ImageIO.write(pb.buffered_image, 'png', java.io.File.new(filename))
      end

      sleep(10)
      ControllableThread.check_for_pause
    end
  end


end

Action.add_action(Raeli.new)
