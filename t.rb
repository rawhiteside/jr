puts "Begin"
require 'java'
require 'mesh-canon'

old_arr = CanonicalLineSegList.load.to_a

newc = CanonicalLineSegList.new
newc.add_xy old_arr

newc.save






