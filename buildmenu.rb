require 'window'
require 'robot'

# Works the build menu
class BuildMenu < AWindow

  BUTTONS = {
    :n => [59, 54],
    :w => [36, 78],
    :e => [82, 78],
    :s => [59, 101],
    :N => [59, 38],
    :W => [19, 78],
    :E => [98, 78],
    :S => [59, 118],
    :nw => [44, 61],
    :ne => [75, 61],
    :sw => [44, 92],
    :se => [74, 92],
    :R => [96, 18],
    :r => [80, 18],
    :L => [22, 18],
    :l => [38, 18],
    :build => [34, 141],
  }
  REVOLVERS = [:r, :l, :R, :L, ]

  def initialize
    rect = WindowGeom.rectFromPoint(Point.new(50, 100))
    super(rect)
  end


  def build(move)
    sleep_sec 0.1
    move = [move] unless move.kind_of?(Array)
    move = optimize_moves(move)
    delay = 0.1
    # Rotations take longer than translations .. the animation on the
    # screen, that is. 
    rdelay = 0.2
    
    extra_delay = 0

    move.each {|dir|
      dialog_click(Point.new(*(BUTTONS[dir])))
      sleep_sec(delay)
      extra_delay += rdelay if REVOLVERS.include?(dir)
    }
    dialog_click(Point.new(*BUTTONS[:build]))
    sleep_sec extra_delay
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
      # :r * 6 --> :R
      if m[:r] >= 6
	m[:r] -= 6
	m[:R] += 1
      end
      # :l * 6 --> :L
      if m[:l] >= 6
	m[:l] -= 6
	m[:L] += 1
      end
      # [:r, :r, :r, :r] --> [:R, :l, :l]
      if m[:r] > 3
	m[:r] -= 4
	m[:R] += 1
	m[:l] += 2
      end
      # [:l, :l, :l, :l] --> [:L, :r, :r]
      if m[:l] > 3
	m[:l] -= 4
	m[:L] += 1
	m[:r] += 2
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
      if REVOLVERS.include?(k)
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
