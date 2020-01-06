require 'action'
require 'window'

class Quarry < Action
  def initialize
    super('Quarry', 'Buildings')
  end


  def setup(parent)
    comps = [
      {:type => :point, :label => 'Drag to pinned dialog', :name => 'point'},
      {:type => :number, :label => 'What number are you (1-4)', :name => 'number'}
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, comps)
  end

  def act
    w = PinnableWindow.from_point(point_from_hash(@vals, 'point'))
    return unless w

    loop do
      heading = heading_for(w)
      work(w, @vals['number'].to_i - 1)
      wait_for_others(w, heading)
    end
    
  end

  # Read the first two lines of the dialog heading.
  # This will change when the quarry advances, and we're
  # ready to work again.
  def heading_for(w)
    w.refresh
    w.read_text.split("\n")[0,2]
  end

  # We've clicked, but need to wait for others to do their part.  The
  # text of the heading will change when everyone has worked.
  def wait_for_others(w, orig_heading)
    loop do
      return if orig_heading != heading_for(w)
      sleep 1
    end
  end

  def work(w, index)
    w.refresh
    lines = w.read_text.split("\n")
    work_lines = lines.delete_if {|l| !(l =~ /Work/)}.sort

    stat_wait('End')

    w.click_on(work_lines[index])
  end

end
Action.add_action(Quarry.new)
