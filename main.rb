require 'rubygems'
require 'refactor-tmp'
require 'action.rb'
require 'user-io'

STDOUT.sync = true
load 'jmain.rb'

if __FILE__ == $0
  MacroMain.new
end
