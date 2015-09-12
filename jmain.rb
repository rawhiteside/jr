require 'java'
require 'action'

import javax.swing.JFrame
import javax.swing.JCheckBox
import javax.swing.JButton
import javax.swing.JPanel
import javax.swing.ToolTipManager
import javax.swing.border.TitledBorder
import java.awt.event.ActionListener
import java.awt.event.ItemListener
import java.awt.event.ItemEvent
import java.awt.Color
import java.awt.Component
import java.awt.BorderLayout
import java.awt.Insets
import javax.swing.BoxLayout

class TopFrame < JFrame
  def initialize
    super
    self.setDefaultCloseOperation(JFrame::EXIT_ON_CLOSE)
    ToolTipManager.shared_instance.initial_delay = 200
    content_panel = JPanel.new(BorderLayout.new)
    self.get_content_pane.add(content_panel)

    @action_panel = JPanel.new
    box_layout = BoxLayout.new(@action_panel, BoxLayout::X_AXIS)
    @action_panel.set_layout(box_layout)
    content_panel.add(@action_panel)

    @groups = {}
  end

  def add_action(action)
    group = group_for(action.group)
    group.add(button_for(action))
  end

  def run
    # Didn't really put the groups into the action_panel.  
    @groups.keys.sort.each do |name|
      @action_panel.add(@groups[name])
    end

    self.pack
    self.set_visible(true)
  end

  def group_for(gname)
    return @groups[gname] if @groups[gname]
    group = JPanel.new
    group.set_layout(BoxLayout.new(group, BoxLayout::Y_AXIS))
    group.set_border(TitledBorder.new(gname))
    group.set_alignment_y(0.0)
    @groups[gname] = group

    group
  end

  def button_for(action)
    panel = JPanel.new
    panel.set_layout(BoxLayout.new(panel, BoxLayout::X_AXIS))
    panel.set_alignment_x(Component::LEFT_ALIGNMENT)
    help = JButton.new('?')
    if HelpForTopic.help_text_for(action.name)
      help.tool_tip_text = 'View or edit the setup instructions.'
    else
      help.set_foreground(Color::PINK) 
      help.tool_tip_text = 'Edit the setup instructions.  They are empty!'
    end
    help.add_action_listener do |e|
      UserIO.show_help(action.name, panel)
    end
    help.set_margin(Insets.new(0,0,0,0))
    panel.add(help)
    check_box = JCheckBox.new(action.name)
    check_box.tool_tip_text = 'Run the macro.'
    check_box.add_item_listener(ActionController.new(action, check_box))
    panel.add(check_box)

    panel
  end
end

class ActionController

  include ItemListener

  def initialize(action, checkbox)
    @action = action
    @checkbox = checkbox
  end

  def itemStateChanged(event)
    if event.get_state_change == ItemEvent::SELECTED
      @action.start(@checkbox) 
      @checkbox.set_background(Color::GREEN)
     @checkbox.set_opaque(true)
      @checkbox.repaint
    else
      @action.stop
      @checkbox.set_opaque(false)
      @checkbox.repaint
    end
  end
end

class MacroMain
  
  def initialize
    # pauseable_robot
    @groups = {}
    @frame = TopFrame.new
    get_actions.each {|a| @frame.add_action(a)}
    @frame.run
  end

  def get_actions
    Dir['actions/*.rb'].each {|f| require f}
    Action.action_list
  end
end

if __FILE__ == $0
  MacroMain.new
end
