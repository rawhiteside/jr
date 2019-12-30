require 'action'
class FileWatch < Action
  BASE = "C:/eGenesis/A Tale in the Desert/egyptc/"
  THING_TO_FILE = {
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
    files = THING_TO_FILE['Pigs']
    loop do
      files.each do |f|
        if File.exist?(BASE + f)
          beep
          UserIO.info('Found a pig')
          return
        end
      end
      sleep 10
    end
  end
  
end
Action.add_action(FileWatch.new)





