class PotencyPush < Action
  def initialize
    super('Potency Push', 'Misc')
  end
  
  def setup(parent)
    gadgets = [
      {:type => :point, :name => 'kitchen', :label => 'Kitchen'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    pt = point_from_hash(@vals, 'kitchen')
    kw = Kitchen.new(pt)
    kw = Kitchen.from_pinnable(kw)

    loop do
      kw.clean_pot
      kw.cook_sink_eat

      # Wait for stats-down.
      sleep 5 while SkillsWindow.new.stat_boosted?
    end
  end

end

class Kitchen < PinnableWindow
  def initialize(pinnable)
    super(pinnable.rect)
  end

  # Clean out the pot
  def clean_pot
    refresh
    ConfirmationWindow.yes if click_on 'Clean'
    sleep 4
  end

  # Cook the sink food and eat it
  def cook_sink_eat
    delay = 4
    refresh
    HowMuch.amount(6) if click_on 'Mix/Add Honey'
    sleep delay
    refresh
    HowMuch.amount(1) if click_on 'Mix/Add Coconut'

    sleep delay
    refresh
    click_on 'Cook'
    popup = PopupWindow.find
    popup.click_on 'OK' if popup
    sleep delay

    # Eat!
    refresh
    click_on 'Enjoy'
    sleep delay
  end

end

Action.add_action(PotencyPush.new)

