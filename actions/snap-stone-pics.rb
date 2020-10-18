require 'action'
require 'actions/abstract_mine'
require 'set'

import org.foa.Globifier
import org.foa.ImageUtils
import org.foa.PixelBlock

class SnapStonePics < AbstractMine
  def initialize
    super('Snapshot stone images', 'Misc')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Drag to pinned mine menu', :name => 'mine'},
      {:type => :text, :label => 'How many stones?', :name => 'stone-count',},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    @debug = @vals['debug'] == 'y'
    log_result "Debug = #{@debug}"
    @stone_count = 7
    @delay = 0.1
    
    w = PinnableWindow.from_point(point_from_hash(@vals, 'mine'))
    
    loop do
      stones = mine_get_globs(w, stone_count)
      save_stones(globs, 'orestone-pics')
    end
  end

  def save_stones(stones, dir)
  end
end

