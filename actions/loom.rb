require 'action'

class Loom < Action
  PRODUCTS_TO_INPUTS = {
    'Linen' => 'Thread',
    'Canvas' => 'Twine',
    'Wool Cloth' => 'Yarn',
    'Silk Cloth' => 'Raw Silk',
    'a Basket' => 'Dried Papyrus',
  }

  def initialize
    super('Loom', 'Buildings')
  end

  def setup(parent)
    comps = [
      {:type => :point, :name => 'loom', :label => 'Pinned loom.'},
      {:type => :combo, :name => 'what',:label => "What to do",
       :vals => PRODUCTS_TO_INPUTS.keys},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, comps)
    @product = @vals['what']
    @input = PRODUCTS_TO_INPUTS[@product]
  end
  
  def reload(loom)
    if loom.click_on("Load the Loom with #{@input}")
      HowMuch.max
    end
  end    

  def restring(loom)
    if loom.click_on('Re-String')
      PopupWindow.dismiss
    end
  end

  def weave_what
    "Weave #{@input} into #{@product}"
  end

  def act
    loom = PinnableWindow.from_point(point_from_hash(@vals, 'loom'))
    loop do
      stat_wait('End')
      loom.refresh
      loom.click_on(weave_what)
      sleep(0.5)

      loom.refresh
      restring loom
      PopupWindow.dismiss

      loom.refresh
      reload loom
      PopupWindow.dismiss
    end
  end
end



Action.add_action(Loom.new)
