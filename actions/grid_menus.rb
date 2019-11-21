class GridMenus < GridAction
  def initialize(name = 'Grid Hotkeys', category = 'Misc')
    super(name, category)
  end

  def get_gadgets
    super + [{:type => :text, :label => 'Menu path', :name => 'menu'},]
  end

  def act_at(p)
    menu = @vals['name']
    win = PinnableWindow.from_screen_click(p)
    win.pin
    loop do
      break if win.click_on(menu)
      sleep 10
    end
  end
end

