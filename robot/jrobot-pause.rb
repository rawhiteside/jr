require 'java'
require 'robot/win32api'
require 'controllable_thread'

# This class watches the NUMLOCK key, and makes corresponding calls to
# ControllableThread.pause_all and .resume_all.  (That's a Java class
# in org.foa)
#
# Instantiating a RobotPauser forks off a thread does the watching and
# pause/resume.  There's no easy was to kill it off.
#
# It makes noise at the tty.  I like that, but turn it off if you
# like.
#
# The key-watcher has to use a WINAPI (GetKeyState) call, since the
# corresponding Java method is borken, and has been borken forever.
# Nobody votes for fixing it on the bug parade.
#
class RobotPauser


  def initialize
    @thread = nil
    @running = nil
    enable_robot_pause
  end

  # Fire up the thread that polls the state of the NUMLOCK
  # key.  If it's toggled ON, then @running is true. 
  # If it's toggled OFF, then we're paused.
  private
  def enable_robot_pause
    return if @thread
    puts "Robot pauser started"
    @thread = Thread.new do
      begin
	watch_num_lock
      rescue Exception => e
        puts "Exception in enable_robot_pause"
	puts e.to_s
	puts e.backtrace.join("\n")
      end
      UserIO.error("Robot pauser terminated.")
      puts "Robot pauser terminated."
    end
  end

  private
  def with_pause_lock
    ControllableThread.pause_all
    begin
      yield
    ensure
      ControllableThread.resume_all
    end
  end

  def watch_num_lock
    
    loop do
      check_key
      if !@running
	# Claim the lock, so others will block
	with_pause_lock do
	  puts 'Pause...'
	  wait_until_running
	end
	puts 'Resume...'
      end
      ControllableThread.sleep_sec 1
    end
  end

  # Poll the NUMLOCK key, and don't return until it's
  # toggled on.
  def wait_until_running
    until @running
      ControllableThread.sleep_sec 1
      check_key
    end
  end    

  # Poll the NUMLOCK key.  Set @running flag to +true+ if the
  # NUMLOCK is toggled on, or to +false+ if it's toggled off.
  GetKeyState = Win32::API.new("GetKeyState", 'I', 'I', 'user32')
  VK_NUMLOCK  = 0x90
  def check_key
    key = GetKeyState.call(VK_NUMLOCK)
    @running = ((1 & key) == 1)
  end
end
