require 'action'
require 'walker'

class RunAndDo < Action
  def initialize
    super('Run and do', 'Misc')
  end

  def persistence_name
    'run_and_do'
  end

  def setup(parent)
    gadgets = [
      {:type => :frame, :label => 'Code.  Takes effect on reload.', :name => 'code',
        :gadgets => [
          {
            :type => :big_text, :label => 'Setup Ruby code', :name => 'code',
            :value => '# Type Ruby code here.',
            :rows => 15, :cols => 50
          },
        ]
      },
      {:type => :combo, :name => 'repeat', :label => 'Repeat?', 
       :vals => ['Repeat', 'One time']},
      {:type => :world_path, :label => 'Path to walk.', :name => 'path',
       :rows => 10, :custom_buttons => 3}
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def init_stuff
    path_text = @vals['path']

    if path_text.include?('Stash')
      @storage = PinnableWindow.from_point(point_from_hash(@vals, 'storage'))
    end
    @coords = WorldLocUtils.parse_world_path(@vals['path'])
    code = @vals['code.code']
    instance_eval(code)
    true
  end

  def act
    return unless init_stuff

    walker = Walker.new
    loop do
      puts "Starting at #{Time.now}"
      @coords.each do |c|
        if c.kind_of? Array
          walker.walk_to(c)
        else
          instance_eval(c) unless c.strip.start_with?("#")
        end
      end
      break if @vals['repeat'] == 'One time'
    end
  end

  # Just spam "H" near the center of the screen.  Should be standing
  # in the GH, and the whole area is active.
  def harvest_greenhouse
    dim = screen_size
    sleep_sec 0.1
    mm(dim.width/2, dim.height/2 + 100)
    sleep_sec 0.1
    send_string 'h'
    sleep_sec 0.1
    mm(dim.width/2, dim.height/2 - 100)
    sleep_sec 0.1
    send_string 'h'
    sleep_sec 0.1
  end
  
  def storage_stash(storage)
    storage.refresh
    sleep 0.2
    HowMuch.max if storage.click_on('Stash./Wood')
    storage.click_on('Stash./Insect/All')
  end
end

Action.add_action(RunAndDo.new)

