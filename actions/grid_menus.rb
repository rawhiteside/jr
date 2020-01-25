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
  end
  def get_gadgets
    super  + [
      {:type => :checkbox, :label => 'Skip center 4', :name => 'should-skip'}
    ]
  end
  def act_at(p)
    return if should_skip?(p)
    win = PinnableWindow.from_screen_click(p['x'], p['y'])
    if win
      HowMuch.max if win.click_on('Load')
    end
  end

  private
  def should_skip?(p)
    return unless @user_vals['should-skip'] == 'true'

    (2..3).cover?(p['ix']) && (3..4).cover?(p['iy'])
  end
    
end
Action.add_action(FillDistaffs.new)
