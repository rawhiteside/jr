require 'action'

class PapyTanks < GridAction
  def initialize
    super('Papy Tanks', 'Buildings')
  end
  
  def get_gadgets
    super  + [
      {:type => :number, :label => 'How many seeds?', :name => 'seed_count',},
    ]
  end
  def start_pass(index)
    @piler = Piler.new
    @windows = []
    @seed_count = @user_vals['seed_count'].to_i
  end

  def act_at(ginfo)

    win = PinnableWindow.from_screen_click(ginfo['x'], ginfo['y'])
    win.pin
    text = win.read_text
    if text.include?('Harvest') || text.include?('Plant')
      @piler.pile(win)
      @windows << win
    else
      win.unpin
    end
  end
  
  def end_pass(index)
    @piler.swap
    @windows.each do |win|
      win.refresh
      win.click_on('Harvest')
      @piler.pile(win)
      sleep 0.3
    end
    @windows.each do |win|
      win.refresh
      win.click_on('Plant')
      HowMuch.amount(@seed_count)
      win.unpin
      sleep 0.5
    end
  end

end
  
Action.add_action(PapyTanks.new)
