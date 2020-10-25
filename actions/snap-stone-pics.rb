require 'action'
require 'actions/abstract_mine'
require 'set'

import org.foa.Globifier
import org.foa.ImageUtils
import org.foa.PixelBlock

class SnapStonePics < AbstractMine
  def initialize
    super('Snapshot stone images', 'Test/Dev')
  end

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Drag to pinned mine menu', :name => 'mine'},
      {:type => :text, :label => 'How many stones?', :name => 'stone-count',},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    w = PinnableWindow.from_point(point_from_hash(@vals, 'mine'))
    stone_count = @vals['stone-count'].to_i
    
    loop do
      globs = mine_get_globs(w, stone_count)
      save_stones(globs, '../discrete-tale/orestone-pics')
    end
  end

  def save_stones(stones, dir)
    stones.each do |glob|
      stone = OreStone.new(@stones_image, glob)
      # Make the rect a bit larger.
      gr = stone.rectangle
      incr = 5
      rect = Rectangle.new(gr.x - incr, gr.y - incr, gr.width + 2*incr, gr.height + 2*incr)
      rect = PixelBlock.clip_to_screen(rect)
      pbMask = PixelBlock.construct_blank(rect, 0x000000);
      pbMask.set_pixels_from_screen_points(glob, 0xffffff)

      pbScene = @stones_image.slice(rect)
      pbAND = ImageUtils.and(pbMask, pbScene)
      name = next_filename(dir)
      pbAND.saveImage(name)
      # pbAND.display_to_user 'A glob'
    end
  end

  def next_filename(dir)
    count_name = File.join(dir, 'count')
    count = 1
    if File.exist?(count_name)
      count = File.read(count_name).to_i
      count += 1
      File.write(count_name, count.to_s)
    else
      File.write(count_name, '1')
    end
    File.join(dir, "%06d.png" % [count])
  end
end

Action.add_action(SnapStonePics.new)
