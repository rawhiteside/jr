require 'java'

java_import javax.swing.JDialog
java_import javax.swing.JOptionPane
java_import javax.swing.JLabel
java_import javax.swing.JComboBox
java_import javax.swing.JTextArea
java_import javax.swing.JScrollPane
java_import javax.swing.JButton
java_import javax.swing.SwingUtilities
java_import javax.swing.JTextField
java_import javax.swing.border.LineBorder
java_import javax.swing.border.TitledBorder
java_import javax.swing.BoxLayout
java_import javax.swing.JPanel
java_import javax.swing.Box

java_import java.awt.Cursor
java_import java.awt.BorderLayout
java_import java.awt.event.ActionListener
java_import java.awt.event.MouseMotionListener
java_import java.awt.event.MouseListener

java_import org.foa.ImagePanel
java_import org.foa.window.ClockLocWindow

require 'yaml'
require 'action-setup-ui.rb'

class UserIO

  # Display a dialog asking stuff from the user.
  # +name+ = persistence tag.  nil for no persistence.
  def self.prompt(parent, name, title, arr, use_defaults = true)
    SetupDialog.new(parent, name, title, arr, use_defaults).execute
  end

  def self.show_help(topic, center_here)
    HelpForTopic.show_help(topic, center_here)
  end

  def self.show_image(buffered_image, title = "An Image")
    img = buffered_image
    if buffered_image.kind_of?(PixelBlock)
      img = buffered_image.buffered_image
    end
    ImagePanel.displayImage(img, title)
  end

  def self.warn(text, title = 'Warning')
    JOptionPane.show_message_dialog(nil, text, title, JOptionPane::WARNING_MESSAGE)
  end

  def self.error(text, title = 'Error')
    JOptionPane.show_message_dialog(nil, text, title, JOptionPane::ERROR_MESSAGE)
  end

  def self.info(text, title = 'Info')
    JOptionPane.show_message_dialog(nil, text, title, JOptionPane::INFORMATION_MESSAGE)
  end
end

class PersistentHash
  def initialize(file)
    @file = file
    @defaults = {}
    @defaults = YAML.load_file(@file) if File.exist?(@file)
  end

  def [](name)
    @defaults[name]
  end

  def []=(name, h)
    @defaults[name] = h
    File.open(@file, 'w') {|f| YAML.dump(@defaults, f)}
  end
end


class HelpForTopic
  @@instance = nil
  @@lock = Monitor.new
  def self.instance
    @@lock.synchronize {
      @@instance = PersistentHash.new('macro-setup.yaml') if @@instance.nil?
    }
    @@instance
  end

  def self.show_help(topic, center_on_this)
    title = "#{topic}"
    text = help_text_for(topic)
    gadgets = [
      {
	:type => :big_text, :editable => true, :label => title,
	:name => 'help', :value => text, :rows => 15, :cols => 40,
        :line_wrap => true
      }
    ]
    vals = UserIO.prompt(center_on_this, nil, title, gadgets)
    return unless vals
    new_text = vals['help']
    HelpForTopic.instance[topic] = new_text if new_text
  end

  def self.help_text_for(topic)
    HelpForTopic.instance[topic]
  end
end
