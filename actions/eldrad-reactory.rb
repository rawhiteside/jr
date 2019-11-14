require 'action'

class EldradReactory < Action
  def initialize
    super("Eldrad reactory", "Misc")
  end
  

  def setup(parent)
    gadgets = [
      {:type => :point, :label => 'Drag to pinned reactory window', :name => 'w'},
      {:type => :combo, :label => 'What to make', :name => 'what', 
        :vals => [
          'Steel, 9 rings',
          'Brass, 10',
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
    @vals = UserIO.prompt(parent, 'Interval keys', 'Interval keys', gadgets)
    return nil unless @vals
    @win = PinnableWindow.fromPoint(point_from_hash(@vals, 'w'))
    @what = @vals['what'].split(',')[1].strip
    @thresh = @vals['thresh'].to_i
  end

  def act
    loop do
      @win.refresh
      text = @win.read_text
      if text =~ /Make/
        # Starting a batch.
        @win.click_on "Make/#{@what}"
        sleep 15
      elsif
        # Got a batch. Is it good?
        match_data = text.match(/strength ([0-9])%/)
        p match_data
        percent = match_data[1].to_i
        p percent
        if percent < @thresh
          @win.click_on 'Reheat'
          sleep 15
        else
          @win.click_on 'Take'
        end
      end
      # waiting....
      sleep 1
    end
  end
end
Action.add_action(EldradReactory.new)

