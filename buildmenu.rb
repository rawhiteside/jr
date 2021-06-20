require 'window'
require 'robot'

# Works the build menu
class BuildMenu < AWindow

  # Number of small rations that equals a large one.
  ROT_STEPS = 30

  BUTTONS = {
    :n => [59, 56],
    :w => [36, 76],
    :e => [82, 76],
    :s => [59, 99],
    :N => [59, 38],
    :W => [19, 76],
    :E => [98, 76],
    :S => [59, 116],
    :nw => [42, 59],
    :ne => [77, 59],
    :sw => [42, 92],
    :se => [76, 92],
    :R => [96, 18],
    :r => [80, 18],
    :L => [24, 18],
    :l => [40, 18],
    :build => [34, 141],
  }
  BIG_R = [:R, :L, ]
  LITTLE_R = [:r, :l, ]

  def initialize
    rect = nil
    wg = LegacyWindowGeom.new
    3.times do
      rect = wg.rectFromPoint(Point.new(50, 100))
      break if rect
      sleep 0.1
    end
    if rect
      super(rect)
    else
      puts 'Build menu not found'
      super(Rectangle.new(0, 0, 0, 0))
    end
  end


  def build(move)
    sleep 0.1
    move = [move] unless move.kind_of?(Array)
    move = optimize_moves(move)
    delay = 0.02
    # Rotations take longer than translations .. the animation on the
    # screen, that is. 
    big_delay = 0.1
    little_delay = 0.08
    t_delay = 0.05
    extra_delay = 0

    move.each {|dir|
      dialog_click(Point.new(*(BUTTONS[dir])))
      sleep(delay)
      extra_delay += big_delay if BIG_R.include?(dir)
      extra_delay += little_delay if LITTLE_R.include?(dir)
      extra_delay += t_delay unless (LITTLE_R.include?(dir) || BIG_R.include?(dir))
    }
    dialog_click(Point.new(*BUTTONS[:build]))
    sleep extra_delay
  end
  
  # Look at the rotations, and optimize them.
  # Especially the rotations, which are slow.
  def optimize_moves(orig)
    # Put counts of each item into a hash.
    m = Hash.new(0)
    orig.each {|e| m[e] += 1}

    # Now, apply optimizations.
    curr_count = sum_values(m)
    prev_count = -1
    while curr_count != prev_count
      annihilate(m, :R, :L)
      annihilate(m, :r, :l)
      # :r * ROT_STEPS --> :R
      if m[:r] >= ROT_STEPS
	m[:r] -= ROT_STEPS
	m[:R] += 1
      end
      # :l * ? --> :L
      if m[:l] >= ROT_STEPS
	m[:l] -= ROT_STEPS
	m[:L] += 1
      end
      # [:r, :r, :r, :r] --> [:R, :l, :l]
      if m[:r] > ROT_STEPS/2
	m[:r] -= (ROT_STEPS/2 + 1)
	m[:R] += 1
	m[:l] += (ROT_STEPS/2 - 1)
      end
      # [:l, :l, :l, :l] --> [:L, :r, :r]
      if m[:l] > ROT_STEPS/2
	m[:l] -= (ROT_STEPS/2 + 1)
	m[:L] += 1
	m[:r] += (ROT_STEPS/2 - 1)
      end
      # 
      # 12 big revolves is the identity
      if m[:L] >= 12
	m[:L] -= 12
      end
      if m[:R] >= 12
	m[:R] -= 12
      end
      # 
      # 7 big revolves is 5 of the opposite.
      if m[:L] >= 7
	m[:L] -= 7
	m[:R] += 5
      end
      if m[:R] >= 7
	m[:R] -= 7
	m[:L] += 5
      end
      prev_count = curr_count
      curr_count = sum_values(m)
    end
    # Sort so that translations come after the rotations.
    trans_arr = []
    rot_arr = []
    m.each_key {|k|
      if BIG_R.include?(k) || LITTLE_R.include?(k)
	m[k].times {|i| rot_arr << k}
      else
	m[k].times {|i| trans_arr << k}
      end
    }

    rot_arr + trans_arr
  end

  def annihilate(h, a, b)
    if h[a] > 0 && h[b] > 0
      h[a] -= 1

      h[b] -= 1
    end
  end

  def sum_values(h)
    sum = 0
    h.each_value {|v| sum += v}

    sum
  end
end
