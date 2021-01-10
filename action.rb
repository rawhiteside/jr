require 'java'
require 'robot'
require 'buildmenu'
require 'user-io'
require 'controllable_thread'
require 'utils'


import java.awt.Point
import java.awt.Rectangle


class Action  < ARobot
  include Utils
  attr_reader :name, :group
  attr_accessor :repeat

  # ctor.  Subclasses should implement a no-arg ctor that calls this.
  def initialize(name, group='Misc')
    @name = name
    @group = group
    @action_thread = nil
    @worker_threads = []
    super()
  end

  @@action_list = []
  def self.add_action(action)
    @@action_list << action
  end

  def self.action_list
    @@action_list.sort{|a,b| a.name.downcase <=> b.name.downcase}
  end

  # Convenience method for Actions.
  def check_for_pause
    ControllableThread.check_for_pause
  end

  # Just for clarity.  Bob gets confused.  But, you can over-ride this
  # if you want the yaml name diff from the display name.
  def persistence_name
    @name
  end

  def action_name
    @name
  end

  # Override to prompt user for info.
  # Return nil if it got canceled.
  def setup(swing_component)
    true
  end

  # Kill the action thread, and all of the worker threads.
  def stop
    @action_thread.kill if @action_thread
    @action_thread = nil
    @worker_threads.each {|t| t.kill}
    @worker_threads = []
  end

  # Fork a worker thread
  def start_worker_thread
    @worker_threads << ControllableThread.new(@name + "-worker") {yield}
  end

  def wait_for_worker_threads
    @worker_threads.each {|t| t.join}
  end

  # Don't over-ride this. I barely undersand it myself. 
  def start(check)
    if @action_thread
      puts "Start called for action already running!"
      return
    end

    @action_thread = ControllableThread.new(@name) do
      begin
	if setup(check)
          # update the "recently used" list. 
          RecentsManager.update(@name)
          puts RecentsManager.most_recent(10)
	  check_for_pause
	  run
	end
      rescue java.lang.InterruptedException => e
	# Nothing.  
      rescue ThreadKilledException => e
	# Nothing.  
      rescue Exception => e
	puts "Action raised exception."
	puts e.to_s
	puts e.backtrace.join("\n")
      end
      @action_thread = nil
      stop
      release_all_locks
      check.set_selected(false)
      puts "Thread for #{@name} completed."
    end


  end

  def release_all_locks
  end

  private
  def run
    puts "Running #{name}"
    begin
      check_for_pause
      act
    rescue java.lang.InterruptedException => e
      # Don't need to do anything.
    rescue ThreadKilledException => e
      # Don't need to do anything.
    rescue java.lang.Exception => e
      puts e.to_string
      puts e.to_s
      puts e.backtrace.join("\n")
      UserIO.error(e.to_string)
    rescue Exception => e
      puts e.to_s
      puts e.backtrace.join("\n")
      UserIO.error(e.to_s)
    end
  end

  # Provide a value hash (as from UserIO.prompt), and a string.
  # This will return a Point from s.x and s.y.
  def point_from_hash(h, s)
    Point.new(h["#{s}.x"].to_i, h["#{s}.y"].to_i)
  end

  def dismiss_all
    AWindow.dismiss_all
  end
end

class GridAction < Action
  def initialize(name, group)
    super(name, group)
    @user_vals = nil
  end

  def get_gadgets
    [
      {:type => :grid, :name => 'g'},
      {:type => :number, :label => 'Repeat count', :name => 'repeat' },
      {:type => :number, :label => 'Delay between grid passes (seconds)', :name => 'delay'},
    ]
  end

  def setup(parent)
    @user_vals = UserIO.prompt(parent, @name, @name, get_gadgets)
  end

  # Override to watch passes begin. 
  def start_pass(index)
  end
  def end_pass(index)
  end

  def act
    delay = @user_vals['delay'].to_f
    repeat = @user_vals['repeat'].to_i
    repeat.times do |i|
      start_pass i
      start = Time.now.to_f
      GridHelper.new(@user_vals, 'g').each_point do |g|
        check_for_pause
	act_at(g)
      end

      wait_more = delay - (Time.now.to_f - start)
      sleep wait_more if wait_more > 0
      end_pass i
    end
  end
end

class GridHelper
  # +h+ : A hash holding the user-speficied grid description.
  # +name+ : The 'name' of that specification in the hash.
  # Thus, if the name is 'g', the hash must have these values in it:
  #    g.top-left.x
  #    f.top-left.y
  #    g.bottom-right.x
  #    g.bottom-right.y
  #    g.num-cols
  #    g.num-rows
  def initialize(h, name)
    @vals = {}
    # 
    # Extract the grid parameters.
    prefix = name + '.'
    keys = [
      'top-left.x', 'top-left.y',
      'bottom-right.x', 'bottom-right.y',
      'num-cols', 'num-rows'
    ]
    keys.each {|k| @vals[k] = h[prefix + k].to_i}
    build_points_array(@vals)
  end

  def build_points_array(g)
    @points = []
    nc = g['num-cols']
    nr = g['num-rows']

    x_step = y_step = 0
    x_step = (g['bottom-right.x'] - g['top-left.x'])/ (nc - 1) if nc > 1
    y_step = (g['bottom-right.y'] - g['top-left.y'])/ (nr - 1) if nr > 1

    y =  g['top-left.y']
    g['num-rows'].times do |iy|
      x =  g['top-left.x']
      g['num-cols'].times do |ix|
	@points << {
	  'x' => x,
	  'y' => y,
	  'ix' => ix,
	  'iy' => iy,
	  'num-cols' => nc,
	  'num-rows' => nr,
	}
	x += x_step
      end
      y += y_step
    end
  end

  # Will yield for each point on the grid.  You'll get a hash with
  # these values as the arg
  #  'x', 'y', 'ix', 'iy', 'num-rows', 'num-cols'
  def each_point
    @points.each {|pt| yield pt }
  end
    
end

