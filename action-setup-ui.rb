require 'java'

import javax.swing.JFrame
import java.awt.event.WindowListener
import javax.swing.WindowConstants
import javax.swing.SwingUtilities
import java.awt.GraphicsEnvironment
import java.awt.GraphicsDevice
import java.awt.Cursor
import java.awt.Font
import javax.swing.JDialog
import javax.swing.JFrame
import javax.swing.JOptionPane
import javax.swing.JLabel
import javax.swing.JCheckBox
import javax.swing.JComboBox
import javax.swing.DefaultComboBoxModel
import javax.swing.JTextArea
import javax.swing.JScrollPane
import javax.swing.JSeparator
import javax.swing.JButton
import javax.swing.SwingUtilities
import javax.swing.JTextField
import javax.swing.border.LineBorder
import javax.swing.border.TitledBorder
import javax.swing.border.EmptyBorder
import javax.swing.BoxLayout
import javax.swing.JPanel
import javax.swing.Box

import java.awt.Cursor
import java.awt.BorderLayout
import java.awt.event.ActionListener
import java.awt.event.MouseMotionListener
import java.awt.event.MouseListener

import org.foa.ImagePanel
import org.foa.window.ClockLocWindow


require 'hook'
require 'yaml'
require 'user-io'

class SetupDialog
  LABEL_SPACING = 10
  GADGET_SPACING = 5
  #
  # +name+ : An action-name to use in persisting the data.  Nil, if
  #     don't want persistence.
  # +gadgets+ : An array of hashes, each of which describes a
  #     gadget.
  # The hash elememts are:
  # A text field:
  # {:type => :text, :label => 'A label', :name => 'the_text'}
  # The allowed types:
  #    :text, :number, :frame, :point, :grid, :big_text, :label, :combo, :world_loc, :world_path
  def initialize(parent_win, name, title, gadgets)
    @parent_win = parent_win
    @name = name
    @title = title
    @gadgets = gadgets
    @defaults = (name ? DialogDefaults.get_defaults(name) : {} )
  end

  # Display the dialog (modally).  Returns a hash of values from the
  # dialog, if user presses "OK".  Otherwise, return nil.
  def execute
    # These hashes, added to by the various gadget creators, of
    # field-name=>Proc.  Calling the get proc will return the field value
    # that was in the dialog. Calling the put proc will set the value.
    @data_get_hash = {}
    @data_put_hash = {}

    # Construct the dialog from the gadgets given to othe constructor
    make_dialog_and_display

    # OK.  It got displayed and we blocked until they hit OK or
    # Cancel. If OK, then we grab the values from the dialog, persist
    # the new values to disk, and return them. If Cancel, we return
    # nil.

    # Clicking on the OK button set @result to 1;  Cancel set it to 0.
    if @result == 1
      @mgr.commit_defaults
      return @mgr.current_dialog_values
    else
      return nil
    end
  end
  
  # Construct the dialog from the initializer gadget list, and
  # return the dialog.
  def make_dialog_and_display
    dialog = JDialog.new(nil, @title)
    dialog.setLayout(BorderLayout.new)

    @center_panel = Box.create_vertical_box
    dialog.add(@center_panel, BorderLayout::CENTER)

    add_ok_cancel(dialog)
    
    GadgetFactory.add_gadget_list(@center_panel, '', @gadgets, @data_get_hash, @data_put_hash)

    @mgr = DialogDefaultsManager.new(dialog, @name, @defaults, @data_get_hash, @data_put_hash)
    dialog.add(@mgr, BorderLayout::NORTH) if  @name

    @mgr.initialize_dialog
    
    dialog.set_modality_type(Java::java.awt.Dialog::ModalityType::APPLICATION_MODAL)
    dialog.pack
    dialog.set_location_relative_to(@parent_win)
    dialog.visible = true
  end

  # Add the bottom stuff.  There's more than just OK and Cancel, now.
  def add_ok_cancel(parent)
    panel = JPanel.new
    panel.border = LineBorder.createBlackLineBorder
    @result = nil
    # 
    # OK button.
    ok = JButton.new("OK")
    ok.add_action_listener do |e|
      @result = 1
      parent.set_visible(false)
    end
    panel.add(ok)
    
    # 
    # Cancel button.
    cancel = JButton.new("Cancel")
    cancel.add_action_listener do |e|
      @result = 0
      parent.set_visible(false)
    end
    panel.add(cancel)
    # 
    # Help button, but just for things with a name.
    if @name
      help = JButton.new("Notes")
      help.tool_tip_text = 'View or edit the setup instructions.'
      help.add_action_listener do |e|
        UserIO.show_help(@name, panel)
      end
      panel.add(help)
    end
    #
    # Always On Top checkbox
    ontop = JCheckBox.new('Keep on top')
    ontop.tool_tip_text = 'Keep this dialog always on top.'
    frame = SwingUtilities.getWindowAncestor(parent)
    frame.always_on_top = false
    ontop.add_item_listener do |event|
      frame.always_on_top = (event.get_state_change == ItemEvent::SELECTED)
    end
    panel.add(ontop)

    parent.add(panel, BorderLayout::SOUTH)
    parent.get_root_pane.set_default_button(ok)
  end


end

# Persists a hash holding defaults for dialogs.
# The hash looks like {'name' => {hash-of-defaults}}
class DialogDefaults
  def self.get_defaults(name)
    full_file = filename_for(name)
    if !full_file.nil? && File.exist?(full_file)
      return YAML.load_file(full_file)
    else
      return {}
    end
  end

  def self.filename_for(name)
    return nil if name.nil?
    # Spaces in filenames are sometimes a pain.
    # Let's don't use them. 
    file = name.gsub(' ', '_')
    return "dialog-defaults/#{file}.yaml"
  end
  
  def self.save_defaults(name, h)
    return if name.nil?
    full_file = filename_for(name)
    File.open(full_file, 'w') {|f| YAML.dump(h, f)}
  end
end

# A full-screen transparent frame.  This is used to make the mouse
# cursor look like crosshairs during screen point acquisition.
class TransparentFrame < JFrame
  def initialize
    super
    setUndecorated(true)
    setOpacity(0.01)  # Aparently, can't be 0.0
    setCursor(Cursor.getPredefinedCursor(Cursor::CROSSHAIR_CURSOR))
    tk = java.awt.Toolkit.getDefaultToolkit
    
    setAlwaysOnTop(true)
    setSize(tk.screen_size.width, tk.screen_size.height)
    setDefaultCloseOperation(WindowConstants::DISPOSE_ON_CLOSE)
  end
end


class MouseDragListener
  include MouseMotionListener
  include MouseListener
  TFRAME = TransparentFrame.new
  
  def initialize(&block)
    @block = block
  end

  def mouseDragged(me)
    pt = me.get_location_on_screen
    @block.call(pt.x, pt.y)
  end

  def mouseMoved(me)
    nil
  end

  def mouseClicked(e)
    nil
  end
  def mouseEntered(e)
    nil
  end
  def mouseExited(e)
    nil
  end

  def mousePressed(e)
    TFRAME.visible = true
    @other_frame = SwingUtilities.getWindowAncestor(e.source)
    @was_on_top = @other_frame.always_on_top
    @other_frame.always_on_top = false
    TFRAME.always_on_top = true
    nil
  end

  def mouseReleased(e)
    TFRAME.visible = false
    TFRAME.always_on_top = false
    @other_frame.always_on_top = @was_on_top
    nil
  end

end


# A TextField gadget with a label.
# 
# {:type => :text, :label => 'How many?', :size => '10', :name => 'count'}
#
class SetupTextGadget < Box
  def initialize(prefix, h, data_gets, data_puts)
    super(BoxLayout::X_AXIS)
    add(SetupLabel.new(h[:label]))
    add(Box.create_horizontal_glue)
    add(Box.create_horizontal_strut(SetupDialog::LABEL_SPACING))
    add(Box.create_horizontal_glue)

    val_key = prefix + h[:name].to_s
    size = h[:size]
    size = 5 unless size
    add(SetupTextField.new(val_key, size.to_i, data_gets, data_puts))
  end
end

class SetupLabelGadget < Box
  def initialize(prefix, h)
    super(BoxLayout::X_AXIS)
    add(SetupLabel.new(h[:label]))
    add(Box.create_horizontal_glue)
    add(Box.create_horizontal_strut(SetupDialog::LABEL_SPACING))
  end
end

class SetupLabel < JLabel
  def initialize(text, border = false)
    super(text)
    set_border(LineBorder.create_black_line_border) if border
  end
end

class SetupTextField < JTextField
  def initialize(val_key, size, data_gets, data_puts)
    super(size)

    set_maximum_size(get_preferred_size())
    data_gets[val_key] = Proc.new { get_text() }
    data_puts[val_key] = Proc.new { |val| set_text(val) }
  end
end

# Adds a screen point-picker.  The hash looks like
#
# {:type => :point, :name => 'top-left', :label => 'label-text'}
#
# The resulting value hash will hold x and y, prefixed with the
# :name provided, as in {'top-left.x' => 12, 'top-left.y' => 13}
class SetupScreenPointGadget < Box
  def initialize(prefix, h, data_gets, data_puts)
    super(BoxLayout::X_AXIS)
    label = SetupLabel.new(h[:label], true)
    label.tool_tip_text = 'L-Drag from this label to the screen point.'
    label.cursor = Cursor.getPredefinedCursor(Cursor::CROSSHAIR_CURSOR)
    add(label)
    add(Box.create_horizontal_strut(SetupDialog::LABEL_SPACING))
    add(Box.create_horizontal_glue)
    cname = prefix + h[:name].to_s
    xbox = SetupTextField.new(cname + '.x', 5, data_gets, data_puts)
    ybox = SetupTextField.new(cname + '.y', 5, data_gets, data_puts)
    tt = 'You can set this by L-dragging from the Label to the screen point.'
    xbox.tool_tip_text = tt
    ybox.tool_tip_text = tt
    
    listener = MouseDragListener.new do |x, y|
      xbox.set_text(x.to_s)
      ybox.set_text(y.to_s)
    end

    label.add_mouse_motion_listener(listener)
    label.add_mouse_listener(listener)

    add(xbox)
    add(ybox)
  end
end

# A large scrollable, editable text area.
#
# {
#   :type => :big_text, :editable => true, :label => 'Label',
#   :name => 'help', :value => 'Initial text value',
#   :rows, :cols, :line_wrap
# }
# 
# The resulting hash will have a 'big-text' key.
#
# The initial_value argument is peculiar to this big_text gadget.
# It's used by various non-setup dialogs to present text that's
# either non-persistent, or is persisted in other ways (i.e., the
# help text).
#
class SetupBigTextGadget < JPanel
  def initialize(prefix, initial_value, h, data_gets, data_puts)
    super()

    area = JTextArea.new
    area.setFont(Font.new("monospaced", Font::PLAIN, 12))


    val_key = prefix + h[:name].to_s
    editable = (h.has_key?(:editable) ? h[:editable] : true)
    area.rows = h[:rows] || 5
    area.columns = h[:cols] || 25

    area.set_border(TitledBorder.new(LineBorder.create_black_line_border, h[:label]))
    data_gets[val_key] = Proc.new do
      area.text
    end
    data_puts[val_key] = Proc.new do |val|
      if !val.nil? && val.size > 0
        area.text = val
        area.caret_position = 0
      end
    end

    area.line_wrap = h[:line_wrap]
    area.wrap_style_word = true
    area.text = initial_value
    
    area.caret_position = 0
    scroll = JScrollPane.new(area)
    scroll.vertical_scroll_bar_policy = JScrollPane::VERTICAL_SCROLLBAR_AS_NEEDED
    scroll.horizontal_scroll_bar_policy = JScrollPane::HORIZONTAL_SCROLLBAR_NEVER
    
    add(scroll)
    @area = area
  end
  def text_area
    @area
  end
end

# Adds a Combo box
# 
# {:type => :combo, :label => 'what color', :name => 'count', :vals => []}
#
# The return value hash will have an entry for 'count'
class SetupCombo < Box
  def initialize(prefix, h, data_gets, data_puts)
    super(BoxLayout::X_AXIS)
    add(SetupLabel.new(h[:label]))
    add(Box.create_horizontal_strut(SetupDialog::LABEL_SPACING))

    combo = JComboBox.new
    h[:vals].each do |val|
      combo.add_item(val.to_s)
    end
    add(combo)

    val_key = prefix + h[:name].to_s

    data_gets[val_key] = Proc.new do
      combo.selected_item
    end
    
    data_puts[val_key] = Proc.new do |val|
      combo.selected_item = val
    end

  end
end

class WorldLocUtils

  # Create a Button that will get the current world coordinates and
  # put them in the target text box.
  def self.current_location_button(target_gadget, insert)
    butt = JButton.new("Current Loc")
    butt.add_action_listener do |e|
      add_this = "Could not get coordinates."
      begin
        win = ClockLocWindow.instance
        if win 
          coords = win.coords
          add_this = "#{coords[0]}, #{coords[1]}"
        end
      rescue Exception => e
      end

      if insert
        add_this = add_this + "\n"
        target_gadget.insert(add_this, target_gadget.caret_position)
      else
        target_gadget.text = add_this
      end
    end
    butt
  end


  
  # Not sure where this method belongs, so it's here for now.  It
  # takes the string from the big_text in the world_path gadget, and
  # parses it into an array of coordinates.
  # 
  # The text "1,2\n3,4" gets parsed into [[1,2],[3,4]] 
  # 
  # Empty lines are ignored.  
  # 
  # Non-numeric text is just kept as a string. Thus, the string
  # "1,2\nhi\n3,4" becomes [[1,2], "hi", [3,4]].
  #
  def self.parse_world_path(text)
    return [] unless text
    return [] if text.strip.size == 0
    rv = []
    regexp = world_location_regexp
    text.split("\n").each do |line|
      next if line.strip.size == 0
      match = regexp.match(line)
      if match
        rv << [match[1].to_i, match[2].to_i]
        next
      else
        rv << line
      end
    end
    rv
  end

  def self.parse_world_location(text)
    return nil if text.strip.size == 0
    regexp = world_location_regexp
    match = regexp.match(text.strip)
    if match
      [match[1].to_i, match[2].to_i]    
    else
      nil
    end
  end

  def self.world_location_regexp
    Regexp.new('^ *([-0-9]+) *, *([-0-9]+) *$')
  end
end

class GadgetFactory
  def self.add_gadget_list(parent, prefix, gadgets, data_gets, data_puts)
    gadgets.each do |h| 
      add_gadget(parent, prefix, h, data_gets, data_puts)
    end
  end

  def self.add_gadget(parent, prefix, h, data_gets, data_puts)
    parent.add(Box.create_vertical_strut(SetupDialog::GADGET_SPACING))
    case h[:type]
    when :world_path
      parent.add(SetupWorldPathGadget.new(prefix, h, data_gets, data_puts))
    when :world_loc
      parent.add(SetupWorldLocationGadget.new(prefix, h, data_gets, data_puts))
    when :text
      parent.add(SetupTextGadget.new(prefix, h, data_gets, data_puts))
    when :number
      parent.add(SetupTextGadget.new(prefix, h, data_gets, data_puts))
    when :combo
      parent.add(SetupCombo.new(prefix, h, data_gets, data_puts))
    when :frame
      parent.add(SetupFrameGadget.new(prefix, h, data_gets, data_puts))
    when :point
      parent.add(SetupScreenPointGadget.new(prefix, h, data_gets, data_puts))
    when :label
      parent.add(SetupLabelGadget.new(prefix, h))
    when :grid
      parent.add(SetupGridGadget.new(prefix, h, data_gets, data_puts))
    when :big_text
      parent.add(SetupBigTextGadget.new(prefix, h[:value], h, data_gets, data_puts))
    else
      UserIO.error("Unknown gadget type: #{h[:type]}")
    end
  end
end

# A gadget to accept world coordinates.  It's a frame with the label
# text.  Inside is a text box and a button that fills the text box
# with the current location in the world.
# 
# Uses: (:type), :label, :size, :name
#

class SetupWorldLocationGadget < JPanel
  def initialize(prefix, h, data_gets, data_puts)
    super()
    # First, a frame with the label.
    border = TitledBorder.new(LineBorder.create_black_line_border, h[:label])
    set_border(border)

    # A box with the text and a "CurrentLoc" button
    box = Box.create_horizontal_box
    # Text box
    val_key = prefix + h[:name].to_s
    size = h[:size] || 13
    txt_box = SetupTextField.new(val_key, size.to_i, data_gets, data_puts)
    box.add(txt_box)
    # CurrentLoc button
    box.add(Box.create_horizontal_glue)
    box.add(WorldLocUtils.current_location_button(txt_box, false))
    box.add(Box.create_horizontal_glue)
    add(box)
  end
end

# A gadget to accept a path in the world.  It's a :big_text with
# coordinates, one per line.
#
# Beside the text area is a "CurrentLoc" button, which will append
# the current world coordinates to the text area.
# 
# Uses: (:type), :label, :rows, :cols, :name, :custom_buttons (=> nil, count)
#
class SetupWorldPathGadget < JPanel
  def initialize(prefix, h, data_gets, data_puts)
    super()
    # First, a frame with the label.
    border = TitledBorder.new(LineBorder.create_black_line_border, h[:label])
    set_border(border)

    # A box with the text and a "CurrentLoc" button
    box = Box.create_horizontal_box

    # Text box
    scroll = SetupBigTextGadget.new(prefix, "", h, data_gets, data_puts)

    box.add(scroll)

    # CurrentLoc button
    button_box = Box.create_vertical_box
    area = scroll.text_area
    button_box.add(WorldLocUtils.current_location_button(area, true))

    count = 0
    count = h[:custom_buttons] unless h[:custom_buttons].nil?
    count.times do |i|
      button_box.add(custom_text_inserter("custom_text_#{i}", area, data_gets, data_puts))
      button_box.add(Box.create_vertical_glue)
    end
    box.add(Box.create_horizontal_glue)
    box.add(button_box)
    box.add(Box.create_horizontal_glue)
    add(box)

  end

  def custom_text_inserter(name, area, data_gets, data_puts)
    custom_panel = JPanel.new
    border = TitledBorder.new(LineBorder.create_black_line_border, 'Custom text inserter')
    custom_panel.set_border(border)

    custom_box = Box.create_vertical_box
    info = { :label => 'Text', :size => 10, :name => name}
    custom_box.add(SetupTextGadget.new('', info, data_gets, data_puts))
    cb = JButton.new('Insert')
    cb.add_action_listener do |e|
      t = data_gets[info[:name]].call
      if !t.nil? && t.size > 0
        cb.set_text t.capitalize
        area.insert(t + "\n", area.caret_position)
      end
    end
    custom_box.add(cb)
    custom_panel.add(custom_box)
    return custom_panel
  end

end

# A grid-picker.  It needs the top-left screen point, the
# lower-right screen point, and the count of rows and columns.  The
# specification hash looks like
#
# {:type => :grid, :name => 'my-grid', :label => '<whatever>'}
#
# The resulting value hash will hold keys:
#  my-grid.top-left.x
#  my-grid.top-left.y
#  my-grid.bottom-right.x
#  my-grid.bottom-right.y
#  my-grid.num-cols
#  my-grid.num-rows
class SetupGridGadget < Box
  def initialize(prefix, h, data_gets, data_puts)
    super(BoxLayout::Y_AXIS)
    grid_gadgets = 
      [{ :type => :frame, :label => h[:label], :name => h[:name], :gadgets => [
	   {:type => :point, :label => 'Drag to top left of grid', :name => 'top-left'},
	   {:type => :point, :label => 'Drag to bottom right of grid', :name => 'bottom-right'},
	   {:type => :number, :label => 'Number of cols', :name => 'num-cols'},
	   {:type => :number, :label => 'Number of rows', :name => 'num-rows'},
         ]
       }]
    GadgetFactory.add_gadget_list(self, prefix, grid_gadgets, data_gets, data_puts)
  end
end

# Adds a Frame with a title that can hold nested gadgets.  The
# hash  looks like:
# 
# {:type=>:frame, :label => 'Frame title', :name => 'group-name', :gadgets => [{ }, { }]}
#
# You'll get a value back for each of the provided gadgets.  The
# key for those values will be prefixed with the group name, as in
# 'group-name.text-val'
class SetupFrameGadget < Box
  def initialize(prefix, h, data_gets, data_puts)
    super(BoxLayout::Y_AXIS)
    border = TitledBorder.new(LineBorder.create_black_line_border, h[:label])
    set_border(border)

    GadgetFactory.add_gadget_list(self, prefix + h[:name] + '.', h[:gadgets], data_gets, data_puts)
  end    
end

class DialogDefaultsManager < Box
  # These keys are non-strings, so that they can't conflict with
  # anything the user can type.
  DISPLAY_MULTI = 1
  CURRENT_SELECTION = 2
  
  # The name of the first auto-created parameter set.
  INITIAL_SET_NAME = 'Parameter set 1'

  def initialize(parent_dialog, action_name, dialog_defaults, data_gets, data_puts)
    super(BoxLayout::Y_AXIS)
    setBorder(LineBorder.createBlackLineBorder)
    @dialog = parent_dialog
    @action_name = action_name
    @dialog_defaults = dialog_defaults
    @data_gets = data_gets
    @data_puts = data_puts
    
    # Maybe the dialog defaults hash is empty.
    @dialog_defaults = empty_parameter_set unless @dialog_defaults.has_key?(DISPLAY_MULTI)
    
    add(@single_view = single_parameter_set_box)
    add(@multi_view = multiple_parameter_set_box)
    if @dialog_defaults[DISPLAY_MULTI]
      show_multi_view
    else
      show_single_view
    end
  end

  # An empty dialog defaults hash.
  def empty_parameter_set
    {
      CURRENT_SELECTION => INITIAL_SET_NAME,
      DISPLAY_MULTI => false,
      INITIAL_SET_NAME => {},
    }
  end

  # The name of the current selection, as specified in @dialog_defaults.
  def current_selection_name
    @dialog_defaults[CURRENT_SELECTION]
  end

  # The data_get_hash got filled with name => Proc
  # We can call the Proc to get the content of the gadget.
  def current_dialog_values
    values = {}
    @data_gets.each { |k, v| values[k] = v.call }
    values
  end

  # Save the dialog defaults for the action.
  # Call this upon "OK".  Not upon "Cancel".
  def commit_defaults
    vals = current_dialog_values
    @dialog_defaults[current_selection_name] = vals
    DialogDefaults.save_defaults(@action_name, @dialog_defaults) 
  end

  # Set the initial values into the dialog.
  # See SetupDialog for how data_puts and data_gets work.
  def initialize_dialog
    set_name = current_selection_name
    vals = @dialog_defaults[set_name]
    @data_puts.each do |k, v|
      if vals[k] 
        v.call(vals[k])
      else
        v.call('')
      end
    end
  end

  # Switch to multi-parameter-set view.
  def show_multi_view
    @single_view.visible = false
    @multi_view.visible = true
    @dialog_defaults[DISPLAY_MULTI] = true
    @dialog.pack
  end

  # Switch to single-parameter-set view.
  def show_single_view
    @single_view.visible = true
    @multi_view.visible = false
    @dialog_defaults[DISPLAY_MULTI] = false
    @dialog.pack
  end

  # This gadget presents the multiple parameter set view.
  def multiple_parameter_set_box
    view = Box.create_vertical_box
    top_row = Box.create_horizontal_box
    top_row.add(collapse_button)
    top_row.add(parameter_set_selection_combo)
    view.add(top_row)
    bottom_row = multi_buttons
    view.add(bottom_row)
    view.add(JSeparator.new)
    view.add(JSeparator.new)
    view
  end

  # The set of buttons at the bottom of the multi-parameter-set view.
  # There's a 'New' button, and an 'Delete' button.
  def multi_buttons
    box = JPanel.new

    new_button = JButton.new('New')
    new_button.add_action_listener do |e| 
      @combo.editable = true
      @combo.editor.select_all
      @last_button_text = 'New'
    end
    box.add(new_button)

    copy_button = JButton.new('Copy')
    copy_button.add_action_listener do |e| 
      @combo.editable = true
      @combo.editor.select_all
      @last_button_text = 'Copy'
    end
    box.add(copy_button)

    delete_set = JButton.new('Delete')
    delete_set.add_action_listener {|e| delete_current_set}
    box.add(delete_set)
    box
  end
  
  def delete_current_set
    curr = current_selection_name
    @combo.remove_item(curr)
    @dialog_defaults.delete(curr)
    current_selection_changed
  end

  
  def parameter_set_names
    @dialog_defaults.keys.delete_if {|k| !k.instance_of? String}.sort
  end

  # The combo box that lets you switch parameter sets
  def parameter_set_selection_combo
    keys = parameter_set_names
    @combo = JComboBox.new(keys.to_java)
    @combo.selected_item = current_selection_name
    # Fires with either the name gets edited (via "New"), or a new
    # selection is made.
    @combo.add_item_listener do |e|
      current_selection_changed if e.state_change == ItemEvent::SELECTED
    end
    @combo
  end

  # This gets called under two circumstances: 1) When a new choice is
  # made from the combo box.  2) When ENTER is pressed after editing
  # the box.
  def current_selection_changed
    item = @combo.selected_item.strip
    keys = parameter_set_names

    # Before we move to new set, update the @dialog_defaults with the
    # current dialog values.
    @dialog_defaults[current_selection_name] = current_dialog_values

    # See if it's a new name.
    if keys.include?(item)
      # Selection changed to an existing one
      @dialog_defaults[CURRENT_SELECTION] = item
      vals = @dialog_defaults[item]

      # Fill in the dialog with new values
      initialize_dialog

    else
      # It's a new item.  This is from either the 'Copy' or tne 'New'
      # button.
      new_name = item
      return if new_name.size == 0
      # Construct the new hash.  Either empty for 'New', of a clone of
      # the current one for 'Copy'
      new_vals = {}
      new_vals = current_dialog_values if @last_button_text == 'Copy'
      @dialog_defaults[new_name] = new_vals
      @dialog_defaults[CURRENT_SELECTION] = new_name
      initialize_dialog

      # Update the combo box model
      @combo.set_model(DefaultComboBoxModel.new(parameter_set_names.to_java))
      @combo.selected_item = new_name
    end
    @combo.editable = false
  end

  # A box holding the single-parameter-set view.
  def single_parameter_set_box
    box = Box.create_horizontal_box
    box.add(expand_button)
    box.add(Box.create_horizontal_glue)
    box
  end

  def expand_button
    btn = JButton.new('v')
    btn.set_border(EmptyBorder.new(0, 0, 0, 0))
    btn.tool_tip_text = 'Show as multiple parameter set view.'
    btn.add_action_listener { |e| show_multi_view }
    btn
  end

  def collapse_button
    btn = JButton.new('^')
    btn.set_border(EmptyBorder.new(0, 0, 0, 0))
    btn.tool_tip_text = 'Show as single parameter set view.'
    btn.add_action_listener { |e| show_single_view }
    btn
  end
end

