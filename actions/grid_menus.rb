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

