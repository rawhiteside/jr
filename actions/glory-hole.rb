require 'action'
require 'walker'

class GloryHole < Action

  KEY_DELAY = 0.05
  def initialize
    super("Glory Hole", "Buildings")
    @rotate_thread = nil
  end

  def stop
    @rotate_thread.kill if @rotate_thread
    @rotate_thread = nil
    super()
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Drag to pinned glory hole window', :name => 'window'},
      {:type => :point, :label => 'Drag to glory hole itself', :name => 'glory-hole'},
      {:type => :text, :label => 'Item to make (menu path)', :size => 15, :name => 'what'},
      {:type => :combo, :label => "Heater Control", :name => "heater", 
       :vals => ['Back Heavy', 'Front Heavy', 'Gradual', 'Pinpoint', 'Standard']},
      {:type => :checkbox, :label => 'Continuous rotate', :name => 'rot?'},
      {:type => :number, :label => 'Rotation interval (secs)', :name => 'rot-interval'},
      {:type => :big_text, :label => 'Recipe', :name => 'recipe', :cols => 35},
      {:type => :number, :label => 'Repeat times', :name => 'count'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end


  def act
    @window = PinnableWindow.from_point(point_from_hash(@vals, 'window'))
    @glory_hole_point = point_from_hash(@vals, 'glory-hole')

    start_making
    start_rotating

    recipe
    cooldown
    stop_rotating
    #unload
  end

  def start_making
    @window.click_on("Heater Control/Set to #{@vals['heater']}")
    @window.refresh
    @window.click_on(@vals['what'])
  end

  def start_rotating
    if @vals['rot?'] == 'true'
      interval = @vals['rot-interval'].to_f
      @rotate_thread = ControllableThread.new { continuous_rotate(interval) }
    end
  end

  def stop_rotating
    @rotate_thread.kill if @rotate_thread
    @rotate_thread = nil
  end

  def stop
    stop_rotating
    super
  end

  def continuous_rotate(interval)
    mm @glory_hole_point, KEY_DELAY
    loop do
      send_string('n', KEY_DELAY)
      sleep_sec interval
    end
  end

  def recipe
    recipe = @vals['recipe']
    recipe.split("\n").each do |line|
      next if (line.strip.size == 0) || (line.strip.start_with? "\#")

      words = line.split(" ")
      words.each do |word|
        if word.to_f != 0.0
          sleep_sec word.to_f
        else
          send_string word, KEY_DELAY
        end
      end
    end
  end

  def cooldown
    19.times {send_string('s', KEY_DELAY)}
    sleep 25
  end

  def unload
  end

end

Action.add_action(GloryHole.new)
