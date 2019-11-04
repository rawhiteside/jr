require 'action'
require 'user-io'

class Kilns < GridAction
  def initialize(name='Kilns', group='Buildings')
    super(name, group)
  end

  def get_gadgets
    super +
      [{:type => :text, :label => 'String to send', :name => 'string'},
       {:type => :number, :label => 'Mouse/key delay', :name => 'key-delay'}]
  end

  def act
    delay = @user_vals['delay'].to_f
    key_delay = @user_vals['key-delay'].to_f
    repeat = @user_vals['repeat'].to_i
    str = @user_vals['string']
    start = nil
    repeat.times do
      str.each_char do |c|
        # Start at fire (the last character)
        start = Time.now.to_f
        GridHelper.new(@user_vals, 'g').each_point do |g|
          with_robot_lock do
            mm(g['x'],g['y'])
            sleep_sec key_delay
	    send_string(c)
            sleep_sec key_delay
          end
        end
      end
      while win = PopupWindow.find
        win.dismiss
        sleep 0.1
      end
      repair_kilns

      wait_more = delay - (Time.now.to_f - start)
      sleep_sec wait_more if wait_more > 0
    end
  end

  def repair_kilns
    # Now, go through and try to repair.
    GridHelper.new(@user_vals, 'g').each_point do |g|
      with_robot_lock do
        menu = PinnableWindow.from_screen_click(g['x'], g['y'])
        dismiss_all unless menu.click_on('Repair')
      end
    end
  end
end

Action.add_action(Kilns.new)

class PotteryWheel < Kilns
  def initialize
    super('Pottery Wheels', 'Buildings')
  end
  def act_at(p)
    
    mm(p['x'],p['y'])
    sleep_sec 0.3
    send_string(@user_vals['string'], @user_vals['key-delay'].to_f)
  end

  def repair_kilns
  end
end
Action.add_action(PotteryWheel.new)


