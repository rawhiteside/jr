require 'mesh-canon'

def gen_map_annotations
  filename = "meshmap.wiki"
  color_str = 'color:"#00FFFF"'

  node_opts = "#{color_str},opacity:1,fill:true,weight:1"
  line_opts = "#{color_str}},opacity:1,fill:true,weight:1"
  node_rad = 1
  
  c = CanonicalLineSegList.load
  File.open(filename, "w") do |f|
    f << "{{CondMap|\n"

    # Write all the path segments.
    c.to_a.each do |xy|
      f << "circ #{xy[0][0]},#{xy[0][1]} #{node_rad} #{node_opts}\n"
      f << "circ #{xy[1][0]},#{xy[1][1]} #{node_rad} #{node_opts}\n"
      f << "line #{xy[0][0]},#{xy[0][1]}:#{xy[1][0]},#{xy[1][1]} #{node_opts} \n"
    end
    # Add the destinations.

    file = "mesh-destinations.yaml"
    name_map = {}
    name_map = YAML.load_file(file) if File.exist?(file)
    name_map.each do |k,v|
      f << "(BallBl) #{v[0]},#{v[1]}, #{k}\n"
    end
    
    
    f << "|contentonly={{{contentonly|no}}}|{{{2}}}}}\n\n" <<
      "<noinclude>[[Category:Atlas|{{PAGENAME}}]]</noinclude>\n"

    puts "Wrote file: #{filename}"
  end
  
end

gen_map_annotations
