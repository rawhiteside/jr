require 'action'

class BlastFurnaces < Action
  def initialize
    super('Blast Furnaces', 'Buildings')
    @threads = []
  end

  def setup(parent)
    gadgets = [
      {:type => :grid, :name => 'g', :label => 'Show me the grid of furnaces.'},
    ]

    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    first_time = true

    loop do
      GridHelper.new(@vals, 'g').each_point do |p|

        w = PinnableWindow.from_screen_click(Point.new(p['x'], p['y']))
        w.pin
        work_pt = Point.new(5, w.rect.y)
        w.drag_to(work_pt)
        
        wait_till_done(w)

        w.refresh
        ConfirmationWindow.yes if w.click_on('Open')
        
        sleep 3
        w.refresh
        w.refresh
        sleep 1
        w.click_on('Take/Every')
        sleep 1
        w.refresh
        sleep 1
        w.click_on('Take/Every')
        
        w.refresh
        sleep 1
        w.click_on('Load the Blast Furnace with Charcoal')
        HowMuch.amount 9

        w.refresh
        sleep 1
        w.click_on('Load the Blast Furnace with Iron')
        HowMuch.amount 991

        w.refresh
        sleep 1
        w.click_on('Fire')

        # Get them spread out a bit.
        sleep 30 if first_time

        w.unpin
      end
      first_time = nil
    end
    
  end
  
  def wait_till_done(w)
    loop do
      w.refresh
      text = w.read_text
      return if text.include? 'Chamber: 54 Iron'
      return if text.include? 'Fire the Blast'
      sleep 3
    end
  end
end

Action.add_action(BlastFurnaces.new)
