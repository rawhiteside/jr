require 'action'
require 'robot/keycodes'
require 'walker'
require 'user-io'

class ResinGather < Action
  Route = [
#    # WH
#    [3955, 3461],

    # WH to next
     [[3955, 3459], [3987, 3459], [3992, 3454]],

    # Next pair
    [4016, 3453],
    [4017, 3453],

    # Under the pair of Broadleafs
    # Hidden[4020, 3446],

    # Next single
     [4026, 3450],

    # One on the other side of the water from here.
    [[4026,3455], [4036,3455],[4036,3451], ],

    # And a pair
    [4048, 3459],
    [4051, 3457],

    # A single just south.
    [4054, 3445],

    # three singles near the road.
    [[4054, 3441], [4076, 3433]],
    [4082, 3434],
    [4080, 3437],
    # Long run to next
    [[4084, 3437], [4090, 3445], [4091, 3460], [4129, 3481]],

    # another long run
    [[4147, 3485], [4250, 3485], [4301, 3485], [4342,3432]],
    [4345, 3432],
    [[4357, 3432],[4357, 3429]],

    # Get around the lake:  the bridge looks too risky.
    [[4357, 3432], [4326, 3432], [4312, 3421], [4312, 3410], [4369, 3409]],
    [4370, 3407],
    [4372, 3406],
    [4377, 3407],

    # Head down south, now, to near the cluster of royals. Three there.
    [4381, 3294],
    [4380, 3292],

    # Further south on the sand.
    [4348, 3214],
    [4346, 3214],

    # Over near the date tree
    [4369, 3173],

    # And over on the sand
    [4340, 3174],
    [4339, 3175],
    [4338, 3175],

    # And near the voting booth.
    [4336, 3160], 
    [4336, 3158], 
    [4338, 3157], 
    [4340, 3158], 

    # Finally, the long treck back to the WH.
    [
      [4247, 3163], [4188, 3197], [4165, 3207], [4137, 3220],
      [4093, 3220], [4093, 3254], [4102, 3272], [4102, 3295],
      [4102, 3389], [4090, 3416], [4061, 3423], 
    ],
    # OK, there was one hawthorn along the way.  Now, continue back.
    [
      [4011, 3419], [3964, 3419], [3955, 3461],
    ],
  ]
  def initialize
    super('Resin run', 'Gather')
    @walker = Walker.new
  end

  def act
    loop do
      Route.each do |p|
	break if p.nil? || p.size == 0
	gather(p)
      end
    end
  end

  def gather(p)
    p = [p] unless p[0].kind_of?(Array)
    @walker.walk_path(p)
    spam_with_r
  end

  def spam_with_r
    box = 150
    head_x = 960
    head_y = 530
    
    x_start = head_x - box
    y_start = head_y - box
    x_stop = head_x + box
    y_stop = head_y + box
    incr = (box * 2) / 20
    y = y_start
    while y < y_stop
      x = x_start
      while x < x_stop
	mm(x, y, 0.006)
	key_press('R'[0], 0.006)
	x += incr
      end
      y += incr
    end
    key_release('R'[0])
  end
end
Action.add_action(ResinGather.new)
