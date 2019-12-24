require 'action'

class PaperPress < Action
  def initialize
    super('Paper press', 'Buildings')
  end


  def setup(parent)
    gadgets = [
      {:type => :label, :label => 'The grid of presses'}, 
      {:type => :grid, :name => 'presses'},
      {:type => :label, :label => 'The grid of hammocks'}, 
      {:type => :grid, :name => 'hammocks'},
      {:type => :number, :label => 'Delay seconds (~100)', :name => 'delay'},
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def act
    delay = @vals['delay'].to_i
    loop do
      each_press {send_string 'p'}
      sleep delay
      each_press {send_string 'p'}
      sleep delay
      each_press {send_string 'r'}
      each_hammock {send_string 't'}
      each_hammock {send_string 'l'}
      each_press {send_string 'l'}
    end
  end

  def each_press
    each_thing('presses') {yield}
  end

  def each_hammock
    each_thing('hammocks') {yield}
  end

  def each_thing(what)
    GridHelper.new(@vals, what).each_point do |p|
      mm(p['x'],p['y'])
      sleep_sec 0.1
      yield
      sleep_sec 0.1
    end
  end
  
end
Action.add_action(PaperPress.new)
