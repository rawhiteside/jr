require 'action'

class WalkTo < Action
  def initialize
    super('Walk', 'Misc')
  end
  def act
    Walker.new.walk_to([-1639, 407])
  end
end

Action.add_action(WalkTo.new)

class WalkToUOB < Action
  def initialize
    super('Walk to UoB', 'Misc')
  end

  
  def act
    paths = {
      'UoArch' =>  [
	[-2357, 403],
	[-1860, 403],
	[-1710, 403],
	[-1710, 715],
	[-1710, 786],
	[-1709, 787], 
	[-1709, 873], 
	[-1711, 876], 
	[-1711, 1173],
	[-1339, 1312],
      ],
      'UoB' =>  [
	[-2357, 403],
	[-1860, 403],
	[-1710, 403],
	[-1710, 715],
      ],
      'UoW' => [
	[-2357, 403],
	[-1860, 403],
	[-1454, 441],
	[-1280, 908],
      ],
    }
    gadgets = [
      {:type => :combo, :label => 'Walk to where?', :vals => paths.keys.sort,
	:name => 'loc'}
    ]
    vals = UserIO.prompt(nil, 'Walk to', 'Walk to', gadgets)
    return unless vals
    loc = vals['loc']
    pts = paths[loc]
    walker = Walker.new
    pts.each {|p| walker.walk_to(p)}
  end
end

Action.add_action(WalkToUOB.new)
