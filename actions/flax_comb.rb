require 'action'
require 'window'

class FlaxComb < Action
  def initialize
    super('Flax Comb', 'Buildings')
  end


  def process(w, max)
    count = 0
    loop do
      w.refresh
      stat_wait('End')
      w.refresh
      if w.click_on('Continue')
	# The idea is to quit the loop before
	# clicking on the next "Clean".
	count += 1
	break if count >= max * 2
	next
      end
      next if w.click_on('Separate')
      w.click_on('Clean')
    end
  end
  
  def setup(parent)
    comps = [
      {:type => :point, :label => 'Drag to comb window', :name => 'w'},
      {:type => :number, :label => 'Number of cycles', :name => 'count'},
    ]
    @vals = UserIO.prompt(parent, @name, @name, comps)
  end

  def act
    count = @vals['count'].to_i
    w = PinnableWindow.from_point(point_from_hash(@vals, 'w'))
    unless w
      UserIO.error('No window found')
      return
    end

    process(w, count)
  end
end
Action.add_action(FlaxComb.new)

