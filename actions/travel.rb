require 'action'
require 'walker'
java_import java.awt.geom.Point2D

class TravelPaths < Action
  def initialize
    super('Travel paths', 'Misc')
  end

  def setup(parent)
    gadgets = [
      {:type => :label, :label => 'Parameter set name (above) must be of the form "<A> to <B>"'},
      {:type => :world_path, :label => 'Path to walk.', :name => 'path', :rows => 20 }
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  # Don't really do anything after defining a new path.
  def act
  end
end
Action.add_action(TravelPaths.new)



class Travel < Action

  def initialize(name = 'Travel')
    super(name, 'Misc')
  end

  def setup(parent)
    @defaults = DialogDefaults.get_defaults('Travel paths')
    @basis = get_basis
    destinations = []
    @basis.each do |b|
      destinations << b[:waypoints].last
    end

    gadgets = [
      {:type => :combo, :name => 'destination', :label => 'Destination?', 
       :vals => destinations.sort.uniq}
    ]
    @vals = UserIO.prompt(parent, persistence_name, action_name, gadgets)
  end

  def get_current_coords
    ClockLocWindow.instance.coords.to_a
  end

  def act
    destination = @vals['destination']
    travel_to(destination)
  end

  def travel_to(destination)
    @defaults = DialogDefaults.get_defaults('Travel paths')
    @basis = get_basis
    current_coords = get_current_coords
    puts "Travel to #{destination}"
    puts "From point #{current_coords}"
    #
    # Compute all possible routes that terminate at the destination.
    routes = all_routes_to(destination)
    if routes.nil?
      puts "Destination #{destination} is unknown."
      return
    end
    #
    # We are located somewhere.  Find the shortest distance
    # (:offset)from our location to a line segment on each of the
    # possible routes.
    # 
    # For each route, we add keys to the hash, giving a total:
    # :waypoints (The list of named spots traversed)
    # :path (The list of coordinstaes to walk)
    # :index (of the first point in the closest line segment)
    # :offset (distance to a point on the line segment)
    # :point (the  point on the line segment closest to us)
    route_infos = find_closest_route_points(current_coords, routes)
    #
    # Sort by offset distance to a defined route.
    route_infos.sort! {|a, b| a[:offset] <=> b[:offset]}
    # 
    # Get the best offset distance, and use that to keep only the
    # routes whose distance is near to that best one.
    best_offset = route_infos[0][:offset]
    route_infos.keep_if {|r| r[:offset] <= best_offset + 2}
    #
    # Modify the path coords to start with the computed intersect
    # point and to exclude points we're skipping by starting at that
    # point.
    route_infos.each do |r|
      index = r[:index]
      r[:path] = [r[:point]] + r[:path][index + 1, r[:path].size]
    end
    #
    # Compute the total distance for our travel.
    route_infos.each do |r|
      dist = r[:offset]
      path = r[:path]
      (path.size - 1).times do |i|
        dist += distance(path[i], path[i+1])
      end
      r[:distance] = dist
    end
    route_infos.sort! {|a, b| a[:distance] <=> b[:distance]}

    Walker.new.walk_path(route_infos[0][:path])
  end

  def print_routes(route, title)
    puts title
    route.each {|rte| p rte}
  end

  def all_routes_to(destination)
    base_list = @basis.select{|b| b[:waypoints].last == destination}
    return nil unless base_list && base_list.size > 0
    
    completed_routes = []
    growing_routes = base_list
    loop do
      temp_list = []

      # Try to grow each route.
      growing_routes.each do |g|
        wp_start = g[:waypoints].first
        found_one = false

        # Find a route whose end matches the growing start.  Concat them.
        @basis.each do |b|
          base_wp_start = b[:waypoints].first
          base_wp_end = b[:waypoints].last
          if  base_wp_end ==  wp_start
            unless g[:waypoints].include?(base_wp_start)
              found_one = true
              temp_list << {
                :waypoints =>  [base_wp_start] + g[:waypoints],
                :path => b[:path] + g[:path]  # Duplicates the end points.  Not a problem. 
              }
            end
          end
        end

        # If we didn't grow the route, then put it onto the completed list.
        completed_routes << g if !found_one
      end
      return completed_routes if temp_list.size == 0

      growing_routes = temp_list
    end # loop
  end

  def get_basis
    basis_set = []
    @defaults.keys.each do |key|
      locs = key.to_s.split(/ to /)
      if locs.size == 2
        coords = WorldLocUtils.parse_world_path(@defaults[key]['path']).keep_if{|elt| elt.kind_of?(Array)}
        vec = {
          :waypoints => [locs[0], locs[1]],
          :path => coords
        }
        basis_set << vec
        basis_set << {
          :waypoints => [locs[1], locs[0]],
          :path => coords.reverse
        }
      end
    end

    basis_set
  end

  # Find the point on each route that's closest to p.  Returns an array of hashes with:
  # :route (the route itself)
  # :index (of the first point in the closest line segment)
  # :offset (to a point on the line segment)
  # :point (the  point on the line segment closest to us)
  def find_closest_route_points(p, routes)

    route_info_list = []
    best_index = best_point = nil

    # Process each route.
    routes.each do |route|
      route_points = route[:path]
      best_offset = 999999.0

      # Look at each line segment in the route
      (route_points.size - 1).times do |index|
        pt1 = route_points[index]
        pt2 = route_points[index + 1]
        pt_closest = get_closest_point(pt1, pt2, p)
        dist = distance(p, pt_closest)
        if dist < best_offset
          best_index = index
          best_offset = dist
          best_point = pt_closest
        end
      end
      route_info_list << {
        :waypoints => route[:waypoints],
        :path => route[:path],
        :index => best_index,
        :offset => best_offset,
        :point => best_point
      }
    end

    return route_info_list
  end

  def distance(p1, p2)
    dx = p1[0] - p2[0]
    dy = p1[1] - p2[1]
    return Math.sqrt(dx * dx + dy * dy)
  end

  # Lifted from stackoverflow.
  # Point on line segment AB that's closest to P.
  def get_closest_point(a, b, p)

    return a if a == b

    a_to_p = [p[0] - a[0], p[1] - a[1]]
    a_to_b = [b[0] - a[0], b[1] - a[1]]

    atb2 = a_to_b[0]**2 + a_to_b[1]**2

    atp_dot_atb = a_to_p[0]*a_to_b[0] + a_to_p[1]*a_to_b[1]

    t = atp_dot_atb.to_f / atb2.to_f

    t = 0.0 if t < 0.0
    t = 1.0 if t > 1.0

    return [(a[0] + a_to_b[0]*t).to_i, (a[1] + a_to_b[1]*t).to_i]

  end


end



Action.add_action(Travel.new)
