require 'java'

import javax.swing.JDialog
import javax.swing.JOptionPane
import javax.swing.JLabel
import javax.swing.JComboBox
import javax.swing.JTextArea
import javax.swing.JScrollPane
import javax.swing.JButton
import javax.swing.SwingUtilities
import javax.swing.JTextField
import javax.swing.border.LineBorder
import javax.swing.border.TitledBorder
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

require 'yaml'
require 'action-setup-ui.rb'

class UserIO

  # Display a dialog asking stuff from the user.
  # +name+ = persistence tag.  nil for no persistence.
  def self.prompt(parent, name, title, arr)
    SetupDialog.new(parent, name, title, arr).execute
  end

  def self.show_help(topic, center_here)
    puts "XXX: topic ls: #{topic}"
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
	:name => 'help', :value => text, :rows => 15, :cols => 30,
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


if __FILE__ == $0
  puts 'Starting'
  gadgets = [
    {:type => :world_path, :label => 'Take a walk?', :name => 'walk-path'},

    {:type => :world_loc, :label => 'Where in the world?', :name => 'coords'},
    {:type => :text, :label => 'How many?', :name => 'count'},
    {:type => :label, :label => 'Ima Label'},
    {:type => :point, :label => 'Show me a point', :name => 'place'},
    {:type => :frame, :label => 'Ima frame', :name => 'frame',
      :gadgets => [
	{:type => :label, :label => 'inner label'},
	{:type => :combo, :label => 'What color?', :vals => ['red', 'green', 'blue'], :name => 'color'},
      ],
    },
    {:type => :grid, :label => 'Show me the array', :name => 'my-grid'},
    {:type => :big_text, :label => 'Type some stuff', :name => 'help-text', :editable => true },
  ]
  rv = UserIO.prompt(nil, 'a name', 'a title', gadgets)
  p rv
  puts 'done'
  exit
end

