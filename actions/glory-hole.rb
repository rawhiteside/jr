require 'action'
require 'walker'

class GloryHole < Action

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
      {:type => :text, :label => 'Item to make (menu path)', :size => 20, :name => 'what'},
      {:type => :checkbox, :label => 'Continuous rotate', :name => 'rot?'},
      {:type => :number, :label => 'Rotation interval', :name => 'rot-interval'},
      {:type => :big_text, :label => 'Recipe', :name => 'recipe'},
      {:type => :number, :label => 'Repeat times', :name => 'count'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end


  def act
    @window = PinnableWindow.from_point(point_from_hash(@vals, 'window'))

    start_making
    recipe
    cooldown
    unload
  end

  def start_making
    @window.click_on(@vals['what'])
    
    if @vals['rot?'] == 'true'
      interval = @vals['rot-interval'].to_s
      @rotate_thread = ControllableThread.new { continuous_rotate(interval) }
    end
  end

  def recipe
  end

  def cooldown
  end

  def unload
  end

end

Action.add_action(GloryHole.new)
