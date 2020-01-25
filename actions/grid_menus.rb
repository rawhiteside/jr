class GridMenus < GridAction
  def initialize(name = 'Grid Menus', category = 'Buildings')
    super(name, category)
  end

  def get_gadgets
    super + [{:type => :text, :label => 'Menu path', :name => 'menu', :size => 20},]
  end

  def act_at(p)
    menu = @user_vals['menu']
    win = PinnableWindow.from_screen_click(p['x'], p['y'])
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
    @windows = []
  end

  def get_gadgets
    super  + [
      {:type => :checkbox, :label => 'Skip center 4', :name => 'should-skip'},
      {:type => :checkbox, :label => 'Start spinning', :name => 'start-spin'},
    ]
  end

  def act_at(p)
    return if should_skip?(p)
    should_spin = (@user_vals['start-spin'] == 'true')
    
    win = PinnableWindow.from_screen_click(p['x'], p['y'])

    win.pin
    win.drag_to(50, 50)
    HowMuch.max if win.click_on('Load')

    if should_spin
      spin(p, win)
    else
      win.unpin
    end
  end

  private
  def spin(g, win)
    @windows << win
    if g['ix'] == (g['num-cols'] - 1) && g['iy'] == (g['num-rows'] - 1)
      @windows.each do |win|
        win.refresh
        win.click_on('Start')
        win.unpin
        sleep 3
      end
    end

  end
  
  def should_skip?(p)
    return unless @user_vals['should-skip'] == 'true'

    return (2..3).cover?(p['ix']) && (3..4).cover?(p['iy'])
  end
    
end
Action.add_action(FillDistaffs.new)
