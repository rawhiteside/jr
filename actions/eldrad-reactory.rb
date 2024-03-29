require 'action'

class EldradReactory < Action
  def initialize
    super("Eldrad reactory", "Misc")
  end
  

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Drag to pinned reactory window', :name => 'w1'},
      {:type => :point, :label => 'Drag to pinned reactory window', :name => 'w2'},
      {:type => :combo, :label => 'How many reactories?', :name => 'count', 
       :vals => ['1', '2']},
      {:type => :combo, :label => 'What to make', :name => 'what', 
       :vals => [
         'Steel, 9 rings',
         'Brass, 10',
         'Electrum, 10',
         'Bronze, 11',
         'Pewter, 10',
         'Sun Steel, 11',
         'Moon Steel, 11',
         'Water Metal, 12',
         "Thoth's Metal, 12",
         'Metal Blue, 13',
         "Octec's Alloy, 14",
       ]         
      },
      {:type => :number, :label => 'Min percent', :name => 'thresh'},
    ]
    @vals = UserIO.prompt(parent, 'Eldrad reactory', 'Eldrad reactory', gadgets)
    return @vals
  end

  def act
    @win1 = PinnableWindow.fromPoint(point_from_hash(@vals, 'w1'))
    if @vals['count'] == '2'
      @win2 = PinnableWindow.fromPoint(point_from_hash(@vals, 'w2'))
    end
    @what = @vals['what'].split(',')[0].strip
    @thresh = @vals['thresh'].to_i

    start_worker_thread{ tend(@win1) }

    if @vals['count'] == '2'
      start_worker_thread{ tend(@win2) }
    end

    wait_for_worker_threads
  end

  def tend(win)
    post_heat_wait = 20
    start = Time.now

    loop do
      win.refresh
      text = win.read_text
      puts text
      if text =~ /Make/
        start = Time.now
        # Starting a batch.
        unless win.click_on "Make/#{@what}"
          puts "Didn't find #{@what}"
        end
        win.refresh
        sleep post_heat_wait
      elsif match_data = text.match(/strength ([0-9 ]+)%/)
        start = Time.now
        # Got a batch. Is it good?
        percent = match_data[1].delete(' ').to_i
        puts "Percent: #{percent}"
        if percent < @thresh
          win.click_on 'Reheat'
          sleep post_heat_wait
        else
          win.click_on 'Take'
        end
      end
      # waiting.... Time out if it's been too long since we last did
      # something.
      if (Time.now - start) > 40
        start = Time.now
        win.click_on 'Reheat'
        sleep post_heat_wait
      end
      sleep 1
    end
  end
end
Action.add_action(EldradReactory.new)

