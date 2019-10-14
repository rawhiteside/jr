require 'action'
import javax.swing.JDialog
import javax.swing.JLabel
import javax.swing.JTextField
import javax.swing.Box
import javax.swing.SwingUtilities

class ColorPicker < Action

  def initialize
    super('Color watcher', 'Test/Dev')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Location to watch', :name => 'loc1'},
      {:type => :point, :label => 'Location to watch', :name => 'loc2'},
      {:type => :point, :label => 'Location to watch', :name => 'loc3'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    pt1 = get_point('loc1')
    pt2 = get_point('loc2')
    pt3 = get_point('loc3')
    
    puts "Label, R, G, B, H, S, B"

    time_start = Time.new
    loop do
      ControllableThread.check_for_pause
      seconds = Time.new - time_start
      show_color(pt1, 'loc1', seconds)
      show_color(pt2, 'loc2', seconds)
      show_color(pt3, 'loc3', seconds)
      rclick_at(747, 450)
      sleep 600
      
    end
  end

  def get_point(tag)
    x = @vals["#{tag}.x"].to_i
    y = @vals["#{tag}.y"].to_i

    Point.new(x, y)
  end

  def show_color(pt, label, seconds)
    rgb = get_color(pt)
    hsb = Color.RGBtoHSB(rgb.red, rgb.green, rgb.blue, nil)
    puts "#{label}, #{seconds}, #{rgb.red}, #{rgb.green}, #{rgb.blue}, #{(hsb[0]* 255).to_i}, #{(hsb[1]* 255).to_i}, #{(hsb[2]* 255).to_i}, "
  end
end


Action.add_action(ColorPicker.new)
