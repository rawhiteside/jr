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

class GridHotkeys < GridAction
  def initialize(name = 'Grid Hotkeys')
    super(name, 'Buildings')
  end

  def get_gadgets
    super +
      [
        {:type => :text, :label => 'String to send', :name => 'string'},
        {:type => :number, :label => 'Mouse/key delay', :name => 'key-delay'},
        {:type => :checkbox, :label => 'Pass for each character.', :name => 'single-char'},
      ]
  end

  def act
    delay = @user_vals['delay'].to_f
    key_delay = @user_vals['key-delay'].to_f
    repeat = @user_vals['repeat'].to_i
    str = @user_vals['string']
    single_chars = (@user_vals['single-char'] == 'true')

    repeat.times do |index|
      start_pass(index)
      send_strs = [str]
      send_strs = str.chars if single_chars 
      start = nil
      send_strs.each do |c|
        # Measure overall delay relative to last operation.
        start = Time.now.to_f
        GridHelper.new(@user_vals, 'g').each_point do |g|
          with_robot_lock do
            mm(g['x'],g['y'])
            sleep key_delay
	    send_string(c, key_delay)
            sleep key_delay
          end
        end
      end
      
      wait_more = delay - (Time.now.to_f - start)
      sleep wait_more if wait_more > 0

      end_pass(index)
    end
  end
end
Action.add_action(GridHotkeys.new)
Action.add_action(GridHotkeys.new('Bricks'))
