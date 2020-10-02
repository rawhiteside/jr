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

  RECORD_STUFF = 'Record more trees and plants.'
  SHOW_LOCATIONS = 'Survey locations.'
  SHOW_PLANT = 'Locations for a plant.'
  SHOW_TREE = 'Locations for a tree.'
  def setup(parent)
    tree_names = @trees.values.collect {|h| h.keys}.flatten.uniq.sort
    plant_names = @plants.values.collect {|h| h.keys}.flatten.uniq.sort

    gadgets = [
      {:type => :combo, :name => 'what', :label => 'Do what:',
       :vals => [RECORD_STUFF, SHOW_LOCATIONS, SHOW_PLANT, SHOW_TREE],
      },

      {:type => :combo, :name => 'which-plant', :label => 'Which plant?',
       :vals => plant_names},

      {:type => :combo, :name => 'which-tree', :label => 'Which tree?',
       :vals => tree_names}
    ]
    @vals = UserIO.prompt(parent, 'Map stuff','Map stuff', gadgets)
  end


  def act
    what = @vals['what']
    if what == RECORD_STUFF
      record_stuff
    elsif what == SHOW_LOCATIONS
      show_locs
    elsif what == SHOW_TREE
      show_item(@trees, @vals['which-tree'])
    elsif what == SHOW_PLANT
      show_item(@plants, @vals['which-plant'])
    end
  end
    
  def show_item(hash, item)
    text = ''
    hash.each_pair do |coords, item_counts|
      count = item_counts[item]
      if count
        text += "(#{pin_for_count(count)}) #{coords[0]}, #{coords[1]}, #{count} items.\n"
      end
    end
    comps = [
      {:type => :big_text, :rows => 20, :cols => 60, :value => text, :name => 'text', :label => item}
    ]
    UserIO.prompt(nil, nil, 'Locations recorded.', comps)
  end

  def pin_for_count(count)
    if count > 0 && count < 9
      return "Bl#{count}"
    else
      return 'Bl9'
    end
  end

  def show_locs
    locs = (@plants.keys + @trees.keys).uniq
    text = locs.inject("") {|accum, loc| accum + "(Bl0) #{loc[0]}, #{loc[1]}, Point\n"}
    comps = [
      {:type => :big_text, :rows => 20, :cols => 60, :value => text, :name => 'text', :label => 'Locations'}
    ]
    UserIO.prompt(nil, nil, 'Locations surveyed', comps)
  end

  def record_stuff
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
          send_vk VK_ESCAPE
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

