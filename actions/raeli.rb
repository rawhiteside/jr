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

    prev_color = nil
    loop do
      px = w.rect.x + 30
      py = w.rect.y + 200
      color = get_color(px, py)
      next if color == prev_color
      w.refresh
      text = w.read_text
      last = text.split("\n").last

      prev_color = color
      
      File.open('Raeli.log', 'a') do |f|
	f.puts("#{Time.now - start}: #{last} : RGB=(#{color.red}, #{color.green}, #{color.blue} ")
      end

      sleep_sec(10)
    end
  end


end

Action.add_action(Raeli.new)
