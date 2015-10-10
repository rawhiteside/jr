require 'java'
require 'robot'
require 'atitd'
require 'user-io'
require 'controllable_thread'

import java.awt.Point
import java.awt.Rectangle

class Action  < ARobot
  
  attr_reader :name, :group
  attr_accessor :repeat

  def initialize(name, group='Misc')
    @name = name
    @group = group
    @action_thread = nil
    super()
  end

  @@action_list = []
  def self.add_action(action)
    @@action_list << action
  end

  def self.action_list
    @@action_list.sort{|a,b| a.name.downcase <=> b.name.downcase}
  end

  # If your macro itself is multi-threaded, you should override this
  # method, and kill all of your threads, then dispatch to this super.
  def stop
    @action_thread.kill if @action_thread
    @action_thread = nil
  end

  # Override to prompt user for info.
  # Return nil if it got canceled.
  def setup(swing_component)
    true
  end

  def start(check)
    if @action_thread
      puts "Start called for action already running!"
      return
    end

    @action_thread = ControllableThread.new(@name) do
      begin
	if setup(check)
	  ControllableThread.check_for_pause
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
      ControllableThread.check_for_pause
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

  # Is the skill-name present and non-red?
  def stat_ok?(skill_name)
    sw = SkillsWindow.new
    color = sw.text_color(skill_name)

    if color.nil? || color == :red || color == 'red'
      return false
    else
      return true
    end
  end

  # Wait for a stat to be non-red in the skills window
  # 'Can't-find-stat' means the same as :red
  def stat_wait(arr)

    arr = [arr] unless arr.kind_of?(Array)

    loop do
      all_ok = true
      arr.each do |stat|
	all_ok = all_ok && stat_ok?(stat)
      end
      return if all_ok
      sleep_sec 1
    end
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
      {:type => :number, :label => 'Delay seconds', :name => 'delay'},
    ]
  end

  def setup(parent)
    @user_vals = UserIO.prompt(parent, @name, @name, get_gadgets)
  end

  def act
    delay = @user_vals['delay'].to_f
    repeat = @user_vals['repeat'].to_i
    repeat.times do
      ControllableThread.check_for_pause
      start = Time.now.to_f
      GridHelper.new(@user_vals, 'g').each_point do |g|
	act_at(g)
      end

      wait_more = delay - (Time.now.to_f - start)
      sleep_sec wait_more if wait_more > 0
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

