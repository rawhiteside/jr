class GridMenus < GridAction
  def initialize(name = 'Grid Menus', category = 'Buildings')
    super(name, category)
  end

  def get_gadgets
    super + [{:type => :text, :label => 'Menu path', :name => 'menu', :size => 20},]
  end

  def act_at(ginfo)
    menu = @user_vals['menu']
    win = PinnableWindow.from_screen_click(ginfo['x'], ginfo['y'])
    win.pin
    loop do
      win.refresh
      break if win.click_on(menu)
      sleep 10
    end
    win.unpin
  end
end
Action.add_action(GridMenus.new)

class FillDistaffs < GridAction
  def initialize
    super('Fill Distaffs', 'Buildings')
  end

  def get_gadgets
    super  + [
      {:type => :checkbox, :label => 'Skip center 4', :name => 'should-skip'},
      {:type => :checkbox, :label => 'Start spinning', :name => 'start-spin'},
    ]
  end

  def start_pass(index)
    @piler = Piler.new
    @windows = nil
  end

  def act_at(ginfo)
    return if should_skip?(ginfo)
    should_spin = (@user_vals['start-spin'] == 'true')
    
    win = PinnableWindow.from_screen_click(ginfo['x'], ginfo['y'])

    win.pin
    @piler.pile(win)
    HowMuch.max if win.click_on('Load')

    if should_spin
      spin(ginfo, win)
    else
      win.unpin
    end
  end

  private
  def spin(g, win)
    if @windows.nil?
      @windows = []
      @row = g['iy']
      @window_row = []
    end

    if @row == g['iy']
      @window_row << win
    else
      # Add a new row to @window
      @window_row.reverse! if (@row % 2) == 0
      @windows << @window_row
      @window_row = [win]
      @row = g['iy']
    end
    
    if g['ix'] == (g['num-cols'] - 1) && g['iy'] == (g['num-rows'] - 1)
      # Add the last row and flatten
      @window_row.reverse! if (@row % 2) == 0
      @windows << @window_row
      @windows.flatten!
      
      # Now, start the spinning
      @windows.each do |win|
        win.refresh
        win.click_on('Start')
        win.unpin
        sleep 2
      end
    end

  end
  
  def should_skip?(p)
    return unless @user_vals['should-skip'] == 'true'

    return (2..3).cover?(p['ix']) && (3..4).cover?(p['iy'])
  end
    
end
Action.add_action(FillDistaffs.new)
