require 'java'
require 'action'

import javax.swing.JFrame
import javax.swing.JCheckBox
import javax.swing.JButton
import javax.swing.JPanel
import javax.swing.ToolTipManager
import javax.swing.border.TitledBorder
import javax.swing.border.LineBorder
import java.awt.event.ActionListener
import java.awt.event.ItemListener
import java.awt.event.ItemEvent
import java.awt.Color
import java.awt.Component
import java.awt.BorderLayout
import java.awt.Insets
import javax.swing.BoxLayout

STDOUT.sync = true

# Here's the top-level interface.
class TopFrame < JFrame
  def initialize
    super

    self.setDefaultCloseOperation(JFrame::EXIT_ON_CLOSE)
    ToolTipManager.shared_instance.initial_delay = 200
    content_panel = JPanel.new(BorderLayout.new)
    self.get_content_pane.add(content_panel)


    content_panel.add(make_top_stuff, BorderLayout::NORTH)

    @action_panel = JPanel.new
    box_layout = BoxLayout.new(@action_panel, BoxLayout::X_AXIS)
    @action_panel.set_layout(box_layout)
    content_panel.add(@action_panel)

    @groups = {}
  end

  
  def make_top_stuff
    box = Box.create_horizontal_box()
    box.add(make_show_hide_button)
    box.add(make_global_setup_button)
    box.add(Box.create_horizontal_glue)
    box.add(make_run_indicator)

    return box
  end

  SHOW_ALL = 'Show all'
  HIDE_SOME = 'Show only favorites'
  def make_show_hide_button
    box = Box.create_horizontal_box()
    button = JButton.new(SHOW_ALL)
    box.add(button)
    button.add_action_listener do |event|
      if button.text == SHOW_ALL
        button.text = HIDE_SOME
        ActionButton.show_all
      else
        button.text = SHOW_ALL
        ActionButton.hide_some
      end
      pack
    end
    return box
  end

  def make_global_setup_button
    
    # Now, add a "Global setup" help button.
    ghelp = JButton.new("Global setup")
    ghelp.add_action_listener do |event|
      UserIO.show_help('Global setup', self)
    end
    return ghelp
  end

  def make_run_indicator
    box = Box.create_horizontal_box()

    # XX Testing gadget
    checkbox = JCheckBox.new("test")
    checkbox.border = LineBorder.create_black_line_border
    checkbox.border_painted = true
    checkbox.background = Color::YELLOW
    # Should be a better way to do this.  Need to curcumvent the
    # pausing that ARobot does.
    robot = java.awt.Robot.new
    checkbox.add_action_listener do |e|
      robot.keyPress VK_NUMLOCK
      sleep 0.01
      robot.keyRelease VK_NUMLOCK
    end
    # A pause listener that fiddles with the checkbox.
    listener = Proc.new do |running|
      if running
        checkbox.opaque = true
        checkbox.text = 'Running'
        checkbox.selected = true
      else
        checkbox.opaque = false
        checkbox.text = 'Paused'
        checkbox.selected = false
      end
    end
    listener.call(RobotPauser.instance.active?)
    RobotPauser.instance.add_pause_listener(listener)
    box.add(checkbox)

    return box
  end



  def add_action(action)
    group = group_for(action.group)
    group.add(button_for(action))
  end

  def run
    # Didn't really put the groups into the action_panel yet, as they
     # needed to be sorted.
    @groups.keys.sort.each do |name|
      @action_panel.add(@groups[name])
    end

    ActionButton.hide_some
    pack
    set_visible(true)
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
    return ActionButton.new(action)


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


# A UI thingy that represents an action.
class ActionButton < JPanel
  
  # Favorite checkbox as a key pointing to action button.
  # These tables don't really belong here...
  FAVORITES = 'favorites.yaml'
  @@fav_to_action = {}
  if File.exist?(FAVORITES)
    @@favorites = YAML.load_file(FAVORITES)
  else
    @@favorites = {}
  end
  
  def initialize(action)
    super()
    set_layout(BoxLayout.new(self, BoxLayout::X_AXIS))
    set_alignment_x(Component::LEFT_ALIGNMENT)

    add(make_favorites_checkbox(action))

    add(make_help_button(action))
    check_box = JCheckBox.new(action.name)

    check_box.tool_tip_text = 'Run the macro.'
    check_box.add_item_listener(ActionController.new(action, check_box))
    add(check_box)
  end

  def make_favorites_checkbox(action)
    check_box = JCheckBox.new('')

    check_box.add_action_listener do |event|
      if check_box.selected
        @@favorites[action.name] = 1
      else
        @@favorites[action.name] = 0
      end
      File.open(FAVORITES, 'w') {|f| YAML.dump(@@favorites, f)}
    end

    check_box.selected = (@@favorites[action.name] == 1)
    check_box.tool_tip_text = 'Mark this action as a favorite.'
    @@fav_to_action[check_box] = self
    check_box
  end

  def make_help_button(action)
    help = JButton.new('?')
    help_text = HelpForTopic.help_text_for(action.name)
    if help_text && help_text.strip.size > 0
      help.tool_tip_text = 'View or edit the setup instructions.'
    else
      help.set_foreground(Color::PINK) 
      help.tool_tip_text = 'Edit the setup instructions.  They are empty!'
    end
    help.add_action_listener do |e|
      UserIO.show_help(action.name, self)
    end
    help.set_margin(Insets.new(0,0,0,0))

    help
  end

  def self.show_all
    @@fav_to_action.each do |key, value|
      key.visible = true
      value.visible = true
    end
  end

  def self.hide_some
    @@fav_to_action.each do |key, value|
      key.visible = false
      if key.selected
        value.visible = true
      else
        value.visible = false
      end
    end
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
