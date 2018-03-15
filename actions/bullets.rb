require 'action'

class Bullets < Action
  def initialize
    super('Bullets', 'Buildings')
    @threads = []
  end

  def persistence_name
    'Bullets'
  end

  def setup(parent)
    gadgets = [
      {:type => :grid, :name => 'g', :label => 'Show me the grid of furnaces.'},
      {:type => :number, :name => 'cc', :label => 'How much CC?'},
      {:type => :number, :name => 'ore', :label => 'How much ore?'},
    ]

    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    loop do
      cc_amount = @vals['cc'].to_i
      ore_amount = @vals['ore'].to_i
      ore_type = 'Iron'

      GridHelper.new(@vals, 'g').each_point do |p|

        pw = PopupWindow.find
        pw.dismiss if pw

        w = PinnableWindow.from_screen_click(Point.new(p['x'], p['y']))
        w.pin
        work_pt = Point.new(5, w.rect.y)
        w.drag_to(work_pt)
        wait_till_done(w)

        sleep_sec 4
        w.refresh
        w.click_on('Take/Every')
        sleep_sec 1

        w.refresh
        if (w.click_on('Load the Bullet Furnace with Charcoal'))
          HowMuch.new(cc_amount)
        end
        sleep_sec 1

        w.refresh
        sleep_sec(0.1)
        w.refresh
        if (w.click_on("Load the Bullet Furnace with #{ore_type} Ore"))
          HowMuch.new(ore_amount)
        end

        sleep_sec 4
        
        w.refresh
        w.click_on('Fire')
        sleep_sec 1

        w.unpin
      end
    end
    
  end

  def wait_till_done(w)
    loop do

      w.refresh
      text = w.read_text

      return unless text.include?('Reaction')
      if text.include?('FireTime: 5')
        w.click_on('Open')
        sleep 1
        ConfirmationWindow.yes
        return
      end
      
      sleep_sec 10
    end
  end

end

Action.add_action(Bullets.new)
