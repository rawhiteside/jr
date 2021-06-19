require 'action'
require 'utils'

class AcroAction < Action
  def initialize
    super('Acro', 'Misc')
  end
  
  def setup(parent)
    gadgets = [
      {:type => :number, :label => 'How many moves?', :name => 'move-count'},
      {:type => :text, :label => 'Which moves to skip? (zero-based)', :name => 'skip-these'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    move_count = @vals['move-count'].to_i
    skip_these = @vals['skip-these']
    skip = []
    skip_these.split(',').each {|s| skip << s.strip.to_i}
    
    x = 225
    y_base = 97
    y_off = 20
    loop do
      move_count.times do |i|
        next if skip.include?(i)
        stat_wait :acro
        lclick_at x, y_base + i * y_off
        sleep 3
      end
    end
  end

end

Action.add_action(AcroAction.new)
