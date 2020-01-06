require 'java'
import org.foa.ThreadKilledException
require 'thread'

class JRunnable
  include Java::java.lang.Runnable
  def initialize(proc)
    @proc = proc
  end
  def run
    begin
      @proc.call
    rescue java.lang.InterruptedException => e
      # do nothing
    rescue ThreadKilledException => e
      # do nothing.
    rescue Exception => e
      puts "Exception in runnable:"
      puts e.to_s
      puts e.backtrace.join("\n")
    end
  end
end

class ControllableThread < org.foa.ControllableThread
  def initialize(name="empty", &block)
    runnable = JRunnable.new(block)
    super(name, runnable)
  end
end

# Don't use the kernel sleep.  Redispatch to ControllableThread instead.
module Kernel
  def sleep(sec)
    ControllableThread.sleepSec(sec)
  end
end

