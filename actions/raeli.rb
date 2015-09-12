require 'action'

class Raeli < Action
  def initialize
    super('Raeli', 'Buildings')
  end

  def setup(parent)
    comps = [
      {:type => :point, :label => 'Drag to pinned Raeli', :name => 'w'},
    ]
    @vals = UserIO.prompt(parent, @name, @name, comps)
  end

  def act
    w = PinnableWindow.from_point(point_from_hash(@vals, 'w'))
    return unless w

    start = Time.now
    w.click_on('Begin')

    prev_pixel = nil
    loop do
      px = w.rect.x + 30
      py = w.rect.y + 200
      pixel = get_pixel(px, py)
      next if pixel == prev_pixel
      w.refresh
      text = w.read_text
      last = text.split("\n").last

      prev_pixel = pixel
      r, g, b = rgb_from_pixel(pixel)

      File.open('Raeli.log', 'a') do |f|
	f.puts("#{Time.now - start}: #{last} : RGB=(#{r}, #{g}, #{b} ")
      end

      sleep_sec(30)
    end
  end


end

Action.add_action(Raeli.new)
