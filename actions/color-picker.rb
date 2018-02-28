require 'action'
import javax.swing.JDialog
import javax.swing.JLabel
import javax.swing.JTextField
import javax.swing.Box
import javax.swing.SwingUtilities

class ColorPicker < Action

  def initialize
    super('Color Picker', 'Test/Dev')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Location to watch', :name => 'loc'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    dialog = make_dialog
    dialog.always_on_top = true
    dialog.visible = true

    watch_point(point_from_hash(@vals, 'loc'))
  end

  def make_dialog
    dialog = JDialog.new(nil, 'Color components')
    dialog.setLayout(BorderLayout.new)

    center_panel = Box.create_horizontal_box
    dialog.add(center_panel, BorderLayout::CENTER)
    rgb_panel = Box.create_vertical_box
    hsl_panel = Box.create_vertical_box
    center_panel.add(rgb_panel)
    center_panel.add(hsl_panel)
    @r = add_text_box('R', rgb_panel)
    @g = add_text_box('G', rgb_panel)
    @b = add_text_box('B', rgb_panel)
    @h = add_text_box('H', hsl_panel)
    @s = add_text_box('S', hsl_panel)
    @l = add_text_box('L', hsl_panel)
    dialog.pack
    
    dialog
  end

  def watch_point(pt)
    loop do
      ControllableThread.check_for_pause
      color = get_color(pt)
      hsb = Color.RGBtoHSB(color.red, color.green, color.blue, nil)
      @r.text = color.red.to_s
      @g.text = color.green.to_s
      @b.text = color.blue.to_s
      @h.text = hsb[0].to_s
      @s.text = hsb[1].to_s
      @l.text = hsb[2].to_s
      sleep_sec(0.1)
    end
  end

  def add_text_box(text, parent)
    box = Box.create_horizontal_box
    box.add(JLabel.new(text))
    text_box = JTextField.new(10)
    box.add(text_box)
    parent.add(box)

    text_box
  end
end

Action.add_action(ColorPicker.new)
