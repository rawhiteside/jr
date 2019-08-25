require 'action'
require 'bounds'
require 'walker'
require 'window'
require 'user-io'
#require 'text_reader'

class WineAction < Action
  def initialize
    super('Vine', 'Plants')
    puts "ran constructor"
	
  end
 
 def persistence_name
	"Tend Vines"
 end 
 def act
   puts "started"
   vals = @vals
   return unless vals
   puts "Recieved values"
    cuttings = {
      'Balance' =>  [
	["Vines are sagging a bit", "Tend : Spread out the Vines", 2],
	[ "Leaves are", "Tend : Shade the Leaves", 2],
	["A musty smell can be detected", "Tend : Aerate the Soil", 8],
	["Stems look especially fat", "Tend : Spread out the Vines", 2],
	["Leaves rustle in the breeze", "Tend : Pinch off the weakest stems", 1],
	["Grapes are starting to shrivel", "Tend : Tie the Vines to the Trellis", 4],
	["Leaves shimmer", "Tend : Shade the Leaves", 5],
      ],
       'BalanceTannin' =>  [
	["Vines are sagging a bit", "Tend : Aerate the Soil", 5],
	[ "Leaves are wilting", "Tend : Mist the Grapes", 5],
	["A musty smell can be detected", "Tend : Tie the Vines to the Trellis", 5],
	["Stems look especially fat", "Tend : Mist the Grapes", 5],
	["Leaves rustle in the breeze", "Tend : Mist the Grapes", 5],
	["Grapes are starting to shrivel", "Tend : Tie the Vines to the Trellis", 5],
	["Leaves shimmer with moisture", "Tend : Mist the Grapes", 5],
      ],
       'BalanceSugar' =>  [
	["Vines are sagging a bit", "Tend : Tie the Vines to the Trellis"],
	[ "Leaves are wilting", "Tend : Mist the Grapes"],
	["A musty smell can be detected", "Tend : Shade the Leaves"],
	["Stems look especially fat", "Tend : Mist the Grapes"],
	["Leaves rustle in the breeze", "Tend : Tie the Vines to the Trellis"],
	["Grapes are starting to shrivel", "Tend : Aerate the Soil"],
	["Leaves shimmer with moisture", "Tend : Spread out the Vines"],
      ],
      'Contemplation' =>  [
	["Vines are sagging a bit", "Tend : Tie the Vines to the Trellis"],
	[ "Leaves are wilting", "Tend : Tie the Vines to the Trellis"],
	["A musty smell can be detected", "Tend : Tie the Vines to the Trellis"],
	["Stems look especially fat", "Tend : Trim the Lower Leaves"],
	["Leaves rustle in the breeze", "Tend : Tie the Vines to the Trellis"],
	["Grapes are starting to shrivel", "Tend : Tie the Vines to the Trellis"],
	["Leaves shimmer with moisture", "Tend : Spread out the Vines"],
      ],
      'Distraction' => [
	["Vines are sagging a bit", "Tend : Shade the Leaves"],
	[ "Leaves are", "Tend : Mist the Grapes"],
	["A musty smell can be detected", "Tend : Mist the Grapes"],
	["Stems look especially fat", "Tend : Spread out the Vines"],
	["Leaves rustle in the breeze", "Tend : Pinch off the weakest stems"],
	["Grapes are starting to shrivel", "Tend : Mist the Grapes"],
	["Leaves shimmer", "Tend : Mist the Grapes"],
      ],
    }

   @tends = cuttings[vals['vineType']]
   @minVigor = vals['vHarvest']
   #deleniate the area that the vineyards might appear
   #@tends.each{|t| puts t[0]}
    box = Bounds.new([vals['ulTend.x'].to_i, vals['ulTend.y'].to_i],
		     [vals['lrTend.x'].to_i, vals['lrTend.y'].to_i])
   sub_boxes = make_regions(box)
   
   #create the walker
   walker = Walker.new
   #move to the lower right coordinate to start the tending
   
   xMin = vals['ul.x'].to_i
   xMax = vals['lr.x'].to_i
   yMin = vals['lr.y'].to_i
   yMax = vals['ul.y'].to_i
   xInterval = vals['interval.x'].to_i
   yInterval = vals['interval.y'].to_i
   @harvest = vals['harvestSetting']
   @totalTends = 0.0
   @readyToHarvest = 0.0
   x = xMin
   y = yMin
   #sleep(2000)
   walker.walk_to([x,y])
   rising = true;
   while true
    until y > yMax
      if rising
        until x > xMax - xInterval
         puts "Probing for Vineyard"
         sub_boxes = make_regions(box)
         tend_once(sub_boxes)
         x += xInterval
         walker.walk_to([x,y])
        end
         rising = !rising
      else
        rising = !rising
        until x < xMin + xInterval
         puts "Probing for Vineyard"
         sub_boxes = make_regions(box)
         tend_once(sub_boxes)
         x -= xInterval
         walker.walk_to([x,y])
        end
      end
      sub_boxes = make_regions(box)
      tend_once(sub_boxes)
      y += yInterval
      walker.walk_to([x,y])
      #sub_boxes = make_regions(box)
      #tend_once(sub_boxes)
    end
    puts "Ready to Harvest" << @readyToHarvest.to_s << " of " << @totalTends.to_s << " for " << ((@readyToHarvest / @totalTends) * 100).to_s << "%"
    @readyToHarvest =0.0
    @totalTends = 0.0
    time1 = Time.new
    puts "Current Time : " + time1.inspect
    puts "Nap Time"
    sleep(3600)
    x = xMin
    y = yMin
    walker.walk_to([x,y])
    rising = true;
  end

 end

   def tend_once(boxes)
      boxes.each do |box|
	   pixel_block = PixelBlock.new(Rectangle.new(box.xmin, box.ymin, box.width, box.height))
        #pixel_block = screen_rectangle(box.xmin, box.ymin, box.width, box.height)
        2.upto(box.height - 2) do |y|
          2.upto(box.width - 2) do |x|
           



            if x > 1 && y >1 && vine_color?(pixel_block, x, y) && vine_color?(pixel_block, x, y -1) && vine_color?(pixel_block, x, y + 1) 
  #              vine_color?(pixel_block, x-1, y-1) &&
   #             vine_color?(pixel_block, x, y-1) &&
    #            vine_color?(pixel_block, x-2, y) &&
     #           vine_color?(pixel_block, x-2, y-2) &&
      #          vine_color?(pixel_block, x, y-2)
                screen_x, screen_y  = pixel_block.to_screen(x, y)



                w = PinnableWindow.from_screen_click(Point.new(screen_x, screen_y))
                #w.drag_to([736,374])
                unless w
                  puts "failed to open menu trying again"
                  next
                end
                do_tend(w)
               sleep 0.1
              return true
            end
          end
        end
      end
      puts "failed to find vineyard"
    return false
  end

  def do_tend(vineWindow)
    line = vineWindow.find_matching_line("Plant")
    if line
       puts "Attempting to plant a new vineyard"
       result = vineWindow.click_on("Plant/Balance")
       if result == nil
         Window.dismiss_all
       end
       return
    end
    conditions = ["Vines are sagging a bit",
      "Leaves are",
      "A musty smell can be detected",
      "Stems look especially fat",
      "Leaves rustle in the breeze",
      "Grapes are starting to shrivel",
      "Leaves shimmer"]
    result = nil
    conditions.each do |c|   
        xy = vineWindow.coords_for(c)
        unless xy == nil
          @tends.each do|t|
		  puts "Found condition" + c.to_s
            if t[0] == c
              #we have found our target tend if we have the vigor do it
              line = vineWindow.find_matching_line("Vigor")
              if line
                  text = ''
                  line.each {|g| text << g.to_s }
                   puts "Vigor Test is : " + text
                  vigor = (text.split(" "))[-1].to_i
                 
                  puts "We think we have " + vigor.to_s
                  
                  if vigor < @minVigor.to_i
                    #puts "I wanted to harvest"
                    if(@harvest == "Yes")
                      result = vineWindow.click_on("Harvest")
                      @totalTends +=1
                    else
                      @readyToHarvest += 1
                      @totalTends +=1
                      result = nil
                      
                    end
                    if result == nil
                      Window.dismiss_all()
                    end         
                    return
                  end
              else
                puts "Attempting to plant a new vineyard"
                result = vineWindow.click_on("Plant. . ./Balance")
                @totalTends += 1
              end
              puts "Condition found: " + c
              puts "we are doing " + t[1]
              result = vineWindow.click_on(t[1].to_s)
              @totalTends +=1
            end
          end
        end

    end
     if result == nil
       Window.dismiss_all()
     end
  end

  def vine_color?(pixel_block, x, y)
	#puts "Looking for a vine color at " + x.to_s + ":" + y.to_s
    c = pixel_block.color(x, y)
    r = c.red
    g = c.green
    b = c.blue

    #puts "Checking pixel values : " + r.to_s + " , " +g.to_s+ " , " + b.to_s


    return false unless r > 30 && r < 38
    #delrg = r - g
    return false unless g > 15 && g < 25
    #delgb = g - b
    return b > 5 && b < 19




    #return false unless r > 122 && r < 130
    #delrg = r - g
    #return false unless delrg > 15 && delrg < 25
    #delgb = g - b
    #return delgb > 5 && delgb < 18


    #Try 1
    #return false unless r > 58 && r < 78
    #delrg = r - g
    #return false unless delrg > 5 && delrg < 35
    #delgb = g - b
    #return delgb > 1 && delgb < 15


    #T6 Numbers
    #return false unless r > 110 && r < 145
    #delrg = r - g
    #return false unless delrg > 25 && delrg < 35
    #delgb = g - b
    #return delgb > 26 && delgb < 35
  end

   # Splits the bounding box into a 5x5 array of sub-boxes.
  def make_regions(bbox)
    spiral = Bounds.new([0,0], [5,5]).spiral
    xvals = []
    yvals = []
    5.times do |i|
      xvals << (bbox.xmin + bbox.width * i * 0.2).to_i
      yvals << (bbox.ymin + bbox.height * i * 0.2).to_i
    end
    xvals << bbox.xmax
    yvals << bbox.ymax

    boxes = []
    spiral.each do |ij|
      i = ij[0]
      j = ij[1]
      boxes << Bounds.new([xvals[i], yvals[j]], [xvals[i+1], yvals[j+1]])
    end

    return boxes
  end


 def setup(parent)
    # Coords are relative to your head in cart view.
   cuttings = {
      'Balance' =>  [
	["Vines are sagging a bit", "Tend : Spread out the Vines"],
	[ "Leaves are", "Tend : Shade the Leaves"],
	["A musty smell can be detected", "Tend : Aerate the Soil"],
	["Stems look especially fat", "Tend : Spread out the Vines"],
	["Leaves rustle in the breeze", "Tend : Pinch off the weakest stems"],
	["Grapes are starting to shrivel", "Tend : Tie the Vines to the Trellis"],
	["Leaves shimmer", "Tend : Shade the Leaves"],
      ],
       'BalanceTannin' =>  [
	["Vines are sagging a bit", "Tend : Aerate the Soil"],
	[ "Leaves are wilting", "Tend : Mist the Grapes"],
	["A musty smell can be detected", "Tend : Tie the Vines to the Trellis"],
	["Stems look especially fat", "Tend : Mist the Grapes"],
	["Leaves rustle in the breeze", "Tend : Mist the Grapes"],
	["Grapes are starting to shrivel", "Tend : Tie the Vines to the Trellis"],
	["Leaves shimmer with moisture", "Tend : Mist the Grapes"],
      ],
       'BalanceSugar' =>  [
	["Vines are sagging a bit", "Tend : Tie the Vines to the Trellis"],
	[ "Leaves are wilting", "Tend : Mist the Grapes"],
	["A musty smell can be detected", "Tend : Shade the Leaves"],
	["Stems look especially fat", "Tend : Mist the Grapes"],
	["Leaves rustle in the breeze", "Tend : Tie the Vines to the Trellis"],
	["Grapes are starting to shrivel", "Tend : Aerate the Soil"],
	["Leaves shimmer with moisture", "Tend : Spread out the Vines"],
      ],
      'Contemplation' =>  [
	[-2357, 403],
	[-1860, 403],
	[-1710, 403],
	[-1710, 715],
      ],
      'Distraction' => [
	["Vines are sagging a bit", "Tend : Shade the Leaves"],
	[ "Leaves are", "Tend : Mist the Grapes"],
	["A musty smell can be detected", "Tend : Mist the Grapes"],
	["Stems look especially fat", "Tend : Spread out the Vines"],
	["Leaves rustle in the breeze", "Tend : Pinch off the weakest stems"],
	["Grapes are starting to shrivel", "Tend : Mist the Grapes"],
	["Leaves shimmer", "Tend : Mist the Grapes"],
      ],
    }
    
    harvest = ["Yes", "No"]
    components = [
      {:type => :point, :label => 'UL Corner of tending region',
	:name => 'ulTend'},
      {:type => :point, :label => 'LR Corner of tending region',
	:name => 'lrTend'},
      {:type => :point, :label => 'UL Corner of Wine Region',
    :name => 'ul'},
        {:type => :point, :label => 'LR Corner of Wine Region',
    :name => 'lr'},
        {:type => :point, :label => 'Interval Between Vineyards',
    :name => 'interval'},
     {:type => :combo, :label => 'Cuttings Only?', :vals => harvest, :name => 'cuttingsSetting'},
        {:type => :number, :label => 'Harvest at Vigor',
    :name => 'vHarvest'},
      {:type => :combo, :label => 'Harvest Grapes?', :vals => harvest, :name => 'harvestSetting'},
  {:type => :combo, :label => 'Use Which Tends?', :vals => cuttings.keys.sort,
    :name => 'vineType'}
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, components)
  end
end


Action.add_action(WineAction.new)
