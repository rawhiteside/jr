require 'rgl/adjacency'
require 'rgl/dijkstra'
require 'java'

java_import java.awt.Point


class MeshGraph
  attr_reader :graph, :weights
  def initialize(mesh)
    @graph = RGL::AdjacencyGraph.new
    @weights = {}
    mesh.each do |xyxy|
      @graph.add_edge(xyxy[0], xyxy[1])
      d = dist(xyxy[0], xyxy[1])
      @weights[[xyxy[0], xyxy[1]]] = d
      @weights[[xyxy[1], xyxy[0]]] = d
    end
  end

  # Construct the path to walk.
  def get_path(curr_xy, dest_xy)
    # path composed of:
    # - walk to get to first edge (may be nil) (edge_walk_xy)
    # - walk to the starting vertex. (start_node)
    # - walk mesh path. 
    # - walk to dest {may be nil) 
    edge_walk_xy = nil
    start_node = nil
    
    
    # Find node closest to dest.  We'll walk to there, then to dest.
    dest_node = find_closest_node(dest_xy)

    # OK, Find the point along the mesh that we should run to from the
    # current location. Not trivial.
    #****************************************************************
    # What's the closest edge to curr?
    closest_edge = find_closest_edge(curr_xy)
    #
    # OK. got the edge.  Is the closest edge point a vertex?
    pt = closest_point_on_lineseg(closest_edge[0], closest_edge[1], curr_xy)
    if pt == closest_edge[0]
      start_node = closest_edge[0]
    elsif pt == closest_edge[1]
      start_node = closest_edge[1]
    else
      edge_walk_xy = pt
      # OK.  Closest pt is along an edge, not a vertex.
      # Which of the two nodes should we walk to?
      dist0 = weight_for_path(closest_edge[0], dest_node) +
              dist(edge_walk_xy, closest_edge[0])
      dist1 = weight_for_path(closest_edge[1], dest_node) +
              dist(edge_walk_xy, closest_edge[1])

      start_node = (dist0 < dist1) ? closest_edge[0] : closest_edge[1]
    end

    full_path = []
    full_path.concat([edge_walk_xy]) unless edge_walk_xy.nil?

    if (start_node == dest_node)
      full_path.concat([start_node])
    else
      pth = @graph.dijkstra_shortest_path(@weights, start_node, dest_node)
      if pth
        full_path.concat(pth)
      else
        raise Exception.new("No path to destination.")
        return nil
      end
    end
    full_path.concat([dest_xy]) unless dest_xy == dest_node

    full_path
  end

  def weight_for_path(v1, v2)
    path = @graph.dijkstra_shortest_path(@weights, v1, v2)
    prev = nil
    weight = 0
    path.each do |v|
      unless prev.nil?
        weight = weight + @weights[[prev, v]]
      end
      prev = v
    end

    weight
  end
  

  def find_closest_edge(xy)
    best_dist = 99000
    best_edge = nil
    @graph.edges.each do |e|
      pxy = closest_point_on_lineseg(e[0], e[1], xy)
      d = dist(pxy, xy)
      if d < best_dist
        best_dist = d
        best_edge = e
      end
    end
    return best_edge
  end

  def find_closest_node(xy)
    best_dist = 99000
    best_node = nil
    @graph.each_vertex do |v|
      d = dist(v, xy)
      if d < best_dist
        best_dist = d
        best_node = v
      end
    end
    return best_node
  end

  # Lifted from stackoverflow.
  # Point on line segment AB that's closest to P.
  def closest_point_on_lineseg(a, b, p)

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

  def dist(xy1, xy2)
    dx = xy1[0] - xy2[0]
    dy = xy1[1] - xy2[1]
    return Math.sqrt(dx * dx + dy * dy)
  end

end
