require 'action'
require 'walker'

class PapyrusAction < PickThings
  def initialize
    super('Papyrus', 'Gather')
  end

  HARVEST_EAST = 'Harvest east'
  HARVEST_WEST = 'Harvest west'
  PLANT = 'Plant'
  LOOP = 'Loop'
  def setup(parent)
    # Coords are relative to your head in cart view.
    gadgets = [
      # {:type => :label, :label => 'Turn off auto-swim!'},
      {:type => :combo, :label => 'What to do:', :name => 'what',
       :vals => [HARVEST_EAST, HARVEST_WEST, PLANT, LOOP]},
      {:type => :point, :label => 'Drag to the pinned WH menu.', :name => 'stash'},
      {:type => :point, :label => 'Drag to the pinned Plant button.', :name => 'plant-button'},
      # {:type => :label, :label => 'All paths start & end near WH.'},
      {:type => :world_path, :label => 'Planting path ["Plant"]', :name => 'plant-path',
       :rows => 5, :custom_buttons => 1},
      {:type => :world_path, :label => 'Gather path, West ["Papy", "Stash"]', :name => 'west-path',
       :rows => 5, :custom_buttons => 1},
      {:type => :world_path, :label => 'Gather path, East ["Papy", "Stash"]', :name => 'east-path',
       :rows => 5, :custom_buttons => 1},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    @stash_window = PinnableWindow.from_point(point_from_hash(@vals, 'stash'))
    plant_button = PinnableWindow.from_point(point_from_hash(@vals, 'plant-button'))
    inventory_window = InventoryWindow.find
    return unless @stash_window && plant_button && inventory_window

    what_to_do = @vals['what']

    log_msg('papy-timing', "Start at #{Time.now}")
    log_msg('harvest-east', "Start at #{Time.now}")
    log_msg('harvest-west', "Start at #{Time.now}")


    loop do
      last_plant_time = Time.now
      wait_to_start_plant
      if what_to_do == LOOP || what_to_do == PLANT
        log_time('plant') {plant_along_path(plant_button)}
      end

      if what_to_do == LOOP || what_to_do == HARVEST_WEST
        coords = WorldLocUtils.parse_world_path(@vals['west-path'])
        log_time('harvest-west') {harvest('harvest-west', coords, inventory_window)}
      end

      if what_to_do == LOOP
        wait_to_start_plant
        log_time('plant') {plant_along_path(plant_button)}
      end

      if what_to_do == LOOP || what_to_do == HARVEST_EAST
        coords = WorldLocUtils.parse_world_path(@vals['east-path'])
        log_time('harvest-east') {harvest('harvest-east', coords, inventory_window)}
      end

      return unless what_to_do == LOOP
    end
  end

  def wait_to_start_plant
    if @last_plant_time.nil?
      @last_plant_time = Time.now
      return
    end
    interval = Time.now - @last_plant_time
    if interval < 610
      puts "Waiting to plant for #{610 - interval} seconds"
      sleep(610 - interval)
    end
    @last_plant_time = Time.now
  end
    
  # Must be standing within reach of the container.
  def plant_along_path(plant_button)
    coords = WorldLocUtils.parse_world_path(@vals['plant-path'])
    walker = Walker.new
    # Get the needed seeds.
    seed_count = coords.count('Plant')
    @stash_window.click_on('Take/Papyrus Seeds')
    HowMuch.amount(seed_count)
    
    coords.each do |coord|
        # Its either coordinates [x, y], or the word "Plant"
        if coord.kind_of?(Array)
	  walker.walk_to(coord)
          last_coord = coord
        elsif coord == 'Plant'
          plant_button.refresh
          plant_button.click_on('Papyrus')
        end
    end
    return 0
  end

  def harvest(label, coords, inventory_window)
    walker = Walker.new
    total_count = 0
    last_coord = nil
    coords.each do |coord|
      # Its either coordinates [x, y], or one of the words "Papy", "Stash".
      if coord.kind_of?(Array)
	walker.walk_to(coord)
        last_coord = coord

      elsif coord == 'Stash'
        @stash_window.refresh
        HowMuch.max if @stash_window.click_on('Stash/Fertile')

      elsif coord == 'Papy'
        walker.post_walk_pause
        count = gather_until_none(walker, last_coord, inventory_window)
        total_count += count
        gather_result(label, last_coord, count, total_count)
      end
    end
    return total_count
  end
  
  def log_time(label)
    start = Time.now
    count = yield
    secs = Time.now - start
    log_msg('papy-timing', "#{label}, #{start}, %d, #{count}" % [secs])
  end
  
  def log_msg(file, msg)
    File.open("log-data/#{file}.csv", 'a') do |f|
      f.puts(msg)
    end
  end

  def gather_result(label, coords, count, total_count)
    log_msg(label, "#{coords[0]}, #{coords[1]}, #{count}, #{total_count}")
  end

  def gather_color?(pixel_block, x, y)
    color = pixel_block.color(x, y)
    r, g, b = color.red, color.green, color.blue
    return (r - g).abs < 8 && (r - b) > 100
  end

  def click_on_this?(pb, pt)
    gather_color?(pb, pt.x, pt.y) &&
      gather_color?(pb, pt.x + 1, pt.y) &&
      gather_color?(pb, pt.x - 1, pt.y) &&
      gather_color?(pb, pt.x, pt.y + 1) &&
      gather_color?(pb, pt.x, pt.y - 1)
  end

end

Action.add_action(PapyrusAction.new)

