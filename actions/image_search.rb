require 'action.rb'
require 'window'

class ImageSearch < Action
  def initialize(name = "Image search", category = 'Test/Dev')
    super(name, category)
  end

  def setup(parent)
    gadgets = [
      {:type => :frame, :name => 'image_def', :label => 'Capture image',
        :gadgets => [
          {:type => :number, :label => ''},
        ],
      },
      
      {:type => :number, }, 
      {:type => :number, }, 
      {:type => :number, }, 
      {:type => :number, :label => 'Second water (~15-30).', :name => 'second'},
      {:type => :number, :label => 'Third water (~30-45).', :name => 'third'},
    ]
    @vals =  UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  
  
  
end
