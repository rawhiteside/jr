require 'action'
require 'window'
require 'yaml'

class MapPlantsTrees < Action
  def initialize
    super("Map plants and trees", "Misc")
    
    # Maps of locations of things.
    # Key is [x, y] world location.
    # Value is another map of {thing-name => count}

    @trees = {}
    @trees_file = 'trees.yaml'
    @trees = YAML.load_file(@trees_file) if File.exist?(@trees_file)
    
    @plants = {}
    @plants_file = 'plants.yaml'
    @plants = YAML.load_file(@plants_file) if File.exist?(@plants_file)
  end

  def setup(parent)
    true
  end


  def act
    loop do
      sleep 0.1
      point = mouse_pos
      pt = [point.x, point.y]
      win = PinnableWindow.from_point(pt[0] + 30, pt[1])
      next if win.nil?
      text = win.read_text
      next if text.nil?
      line1 = text.split("\n")[0]
      # 
      # Plant?
      match = line1.match("This is a (.*)")
      if match
        add_entry(@plants, match[1].strip, @plants_file)
        send_vk VK_ESCAPE
      else

        match = line1.match("This (.*) produces")
        if match
          add_entry(@trees, match[1].strip, @trees_file)
          dismiss_all
          mm point
        end
      end
    end
  end

  def add_entry(hash, item, file)
    coords = ClockLocWindow.instance.coords.to_a
    loc_hash = hash[coords] || {}
    item_count = loc_hash[item] || 0
    loc_hash[item] = item_count + 1
    hash[coords] = loc_hash

    File.open(file, 'w') {|f| YAML.dump(hash, f)}
    if item.include?('?')
      beep
      p item
    end
  end

end

Action.add_action(MapPlantsTrees.new)

