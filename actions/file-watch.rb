require 'action'
require 'robot/keycodes.rb'

class FileWatch < Action
  BASE = "C:/Program Files (x86)/Desert Nomad Studios/A Tale In The Desert/egyptc/"
  THING_TO_FILE = {
    "cicadas" => ["ega0e00af7c9c816e63f7b37d0b04061ec6da068498.ega"],

    "Pigs" => [ 
      "ega179815eb10121f14dcb76c39555f9ca10730dc14.ega", 
      "egab75515f8819f22267d6e66748581ed382500345a.ega",
      "ega10a4efd3313ca13379da90dceb9e985d32feab5f.ega",
    ]
  }
  def initialize
    super('File Watch', 'Misc')
  end


  def act
    files = THING_TO_FILE['cicadas']
    loop do
      check_for_pause
      files.each do |f|
        if File.exist?(BASE + f)
          beep
          send_vk(VK_NUMLOCK)
          sleep 1
          UserIO.info 'Found a pig'
          return
        end
      end
      sleep 10
    end
  end
  
end
Action.add_action(FileWatch.new)





