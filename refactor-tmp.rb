# This is temporary.  I need a place to put stuff temporarily
# during the port to Java.
#
require 'java'
require 'controllable_thread'

import java.awt.Rectangle
import java.awt.Dimension

def sleep_sec(seconds)
  begin
    java.lang.Thread.sleep((seconds * 1000).to_i)
  rescue Exception => e
    raise ThreadKilledException.new
  end
end

