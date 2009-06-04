# street_gen.rb
#---------------------------------------------------------------------------------------------------
# Version: 0.5.0a
# Compatible: SketchUp 7 (PC)
#             (other versions untested)
#---------------------------------------------------------------------------------------------------
#
# CHANGELOG
# 0.1.0a - 15.05.2009 (Thom)
#		 * Initial build. Offset edges into streets.
#
# 0.2.0a - 24.05.2009 (Thom)
#		 * Rounded corners.
#
# 0.3.0a - 30.05.2009 (Thom)
#		 * Rounded corners are now created as part of the face itself. No more separate group.
#
# 0.3.1a - 31.05.2009 (Thom)
#		 * Added check for the core and correct path installation.
#
# 0.3.2a - 31.05.2009 (Thom)
#		 * Fixed a bug in the core installation check.
#
# 0.4.0a - 31.05.2009 (Thom)
#		 * Finds the blocks between the streets and generates faces.
#        * Tags generated geometry.
#        * Version constant.
#
# 0.4.1a - 01.06.2009 (Thom)
#		 * Fixed a syntax error.
#
# 0.5.0a - 02.06.2009 (Thom)
#		 * Varaible street width.
#
#---------------------------------------------------------------------------------------------------
#
# KNOWN ISSUES
# * ...
#
#---------------------------------------------------------------------------------------------------
#
# TO-DO / NEXT
# * Toolbar.
# * Default street properties.
# * Custom street properties by edge material.
# * Street modifier tool - Modify the street segments of existing streets.
# * Error handling
# * Length from corner, instead of radius?
#
#---------------------------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#---------------------------------------------------------------------------------------------------

### CORE & INSTALLATION CHECK ### ------------------------------------------------------------------
# Core check
if not file_loaded?('city_gen.rb')
	if Sketchup.find_support_file('city_gen.rb', 'Plugins/citygen/') == nil
		UI.messagebox('The CityGen\'s core files is missing. Install the required core files.')
	else
		UI.messagebox('The CityGen\'s core files is not loaded. Ensure you installed this plugin correctly.')
	end
	raise 'CityGen Core error.'
end 
# Correct installation check
if Sketchup.find_support_file('citygen/modules/' + File.basename(__FILE__), 'Plugins') == nil
	UI.messagebox("This module (#{File.basename(__FILE__)}) has not been installed properly. It should be installed under Plugins\\citygen\\modules\\")
	raise 'CityGen Module path error.'
end

### MODULES ### ------------------------------------------------------------------------------------
module City_Gen
	
	module Street_Gen
		
		### CONSTANTS ### --------------------------------------------------------------------------
		unless file_loaded?('street_gen.rb')
			VERSION = '0.5.0'
			MODULE_ID = 'Street_Gen'
			GENERATOR_ID = MODULE_ID + '-' + VERSION
		end
		
		### MENUS & TOOLBARS ### -------------------------------------------------------------------
		unless file_loaded?('street_gen.rb')
			# Commands
			cmd_generate_streets = UI::Command.new('Generate Streets') {
				City_Gen::Street_Gen.selection_streets_from_centre_lines
			}
			
			# Menus
			City_Gen.menu.add_item(cmd_generate_streets)
		end 
		
		### METHODS ### ----------------------------------------------------------------------------
		def self.selection_streets_from_centre_lines
			sel = Sketchup.active_model.selection.to_a
			sel.reject! { |e| !e.kind_of?(Sketchup::Edge) }
			self.streets_from_centre_lines(sel)
			# (!) Must also be able to select a group containing edges as that probably what the 
			#     Street Map Generator will create.
		end
		
		
		def self.streets_from_centre_lines(edges)
			model = Sketchup.active_model
			sel = model.selection
			
			# Prompt for street properties
			# (!) This should be moved to a separate function that sets the default properties.
			#     Then custom street width is set by using materials. For now this will do.
			prompts = ['Width', 'Corner Radius', 'Min. Rounding Angle', 'Create Blocks']
			defaults = [10000.mm.to_s, 3000.mm.to_s, 30.to_s, 'No']
			lists = ['', '', '', 'Yes|No']
			input = UI.inputbox(prompts, defaults, lists, 'Street Properties')
			
			return if input == false
			
			road_width		= input[0].to_l / 2
			corner_radius	= input[1].to_l
			minimum_round_angle = input[2].to_i.degrees
			create_blocks	= (input[3] == 'Yes') ? true : false
			
			
			puts "\nGenerating Streets from #{edges.length} edges..."
			
			Helping_Hand.start_operation('Streets from Edges')
			
			g = model.entities.add_group
			g.set_attribute('CG_Streets', 'Generator', self::GENERATOR_ID)
			edges.each { |edge|
				self.edge_to_street(edge, road_width, corner_radius, minimum_round_angle, g.entities)
			}
			
			# Hide internal edges.
			# (!) Profile how long this takes.
			self.hide_internal_edges(g.entities)
			
			# Find the block inbetween the streets.
			# (!) Profile how long this takes.
			self.find_blocks(g.entities) if create_blocks
			
			model.commit_operation
		end
		
		
		# Hides all edges that's connected to two faces.
		def self.hide_internal_edges(entities)
			entities.each { |e|
				next unless e.kind_of?(Sketchup::Edge)
				e.hidden = true if e.faces.length > 1
			}
		end
		
		
		# Find the blocks between the streets
		# This function is a complete mess! Need to do this in a much more efficient way.
		def self.find_blocks(entities)
			# Extract all the edges from the entities collection
			edges = entities.to_a.reject { |e| !e.kind_of?(Sketchup::Edge) }
			
			# Hash of all the blocks found.
			# key = Set.new <- collection of edges for the block
			# value = total length of all the edges
			blocks = {}
			
			puts "> Finding Blocks - Edges: #{edges.length}"
			while edges.length > 0
				
				# Fetch an edge from our collection of edges which we will use as a starting point
				# to track the boundary of this block.
				edge = edges.shift
				# Validate starting edge. We don't want to start with an internal edge.
				next if edge.faces.length != 1
				# Current collection of edges for this block.
				block_edges = [edge]
				# Set of vertices that makes up this block. There will be no duplicate and they will
				# appear in the order we need them to create the face.
				block = Set.new
				# Insert first set of data.
				block.insert(edge.start)
				block_size = edge.length
				
				# Follow the connected edges until we have found the boundary of this block. 
				current_edge = edge
				until current_edge.nil?
					# Check each vertex for connected edges. We want any new edges that are
					# connected to only one face.
					current_edge.vertices.each { |v|
						# This ensures that we stop if we later can't find a suitable edge.
						current_edge = nil
						# We check each vertex. If it has an edge connected that's not already added
						# and it only has one face connected, then we want this edge. We then collect 
						# the data we need from it and continue to the next.
						v.edges.each { |e|
							if !block.include?(v) && e.faces.length == 1 && !block_edges.include?(e)
								current_edge = e
								block_edges << e
								block.insert(v)
								block_size += e.length
							end
						}
					}
				end
				# Add this block to the collection of blocks. We'll draw the geometry later.
				blocks[block] = block_size
				# Remove the edges we'e used from the collection, as we don't want to use these
				# more than just this one time.
				edges = edges - block_edges
			end
			
			puts "> Complete! - #{blocks.length} blocks found"
			
			# Sort the blocks hash by the value. The value contains the total length of the
			# block's edges. We take the largest one out as it's the boundary of our whole
			# street geometry.
			# (!) What if there's unconnected street geometry? Then there'd be more blocks to ignore.
			sorted_blocks = blocks.sort { |a,b| a[1]<=>b[1] }
			boundary = sorted_blocks.pop # Remove the largest block, as that's really the boundary.
			
			# Create the group to contain the generated geometry.
			group = Sketchup.active_model.entities.add_group
			group.set_attribute('CG_Block', 'Generator', self::GENERATOR_ID)
			# Get the Point3d objects of all the vertices we got and create a face.
			sorted_blocks.each { |block, area|
				points = block.to_a.collect { |b| b.position }
				face = group.entities.add_face(points)
				face.reverse! if face.normal.z < 0 # Ensure that the face is pointing upwards.
			}
		end
		
		
		# Creates a face from the given edge segment.
		# road_width is actually half the road width. It's the length from the centre line to
		# the road edge.
		def self.edge_to_street(edge, road_width, corner_radius, minimum_round_angle, entities)
			#puts "\n ##### Edge 2 Street ##### "
			
			# Variables
			model = Sketchup.active_model
			sel = model.selection

			# Mark the start and end of line
			#model.entities.add_text( 'Start', edge.start.position, [10,10,10] )
			#model.entities.add_text( 'End',   edge.end.position, [-10,-10,10] )
			
			# Arrays of points. The order they are added and removed are important. (!) Explain.
			points = []
			
			#i = 0
			
			# Check each vertex for connected edges and calculate the intersecting offset lines.
			edge.vertices.each { |v|
				#puts v
				point_right = nil
				point_left = nil
			
				# Get offset Line objects starting from the opposite end.
				base_street = CG_Street.new(edge.material)
				base_width = (base_street.width.nil?) ? road_width : base_street.width / 2
				
				base_offset_lines = self.get_offset_lines(edge, v, base_width)
				base_line_right = base_offset_lines[0]
				base_line_left  = base_offset_lines[1]
				
				base_line_rev_right = base_offset_lines[2]
				base_line_rev_left  = base_offset_lines[3]
				
				# Variables to keep track of the intersecting points.
				min_len_right = nil
				min_len_left  = nil
				
				# Variables for rounding corners.
				right_angle = nil
				left_angle = nil
				
				# If this is an end line, we pick the start point.
				if v.edges.length == 1
					#puts 'Adding 2 points...'
					points << base_line_rev_left[0]
					points << base_line_rev_right[0]
				end
				
				# Iterate over each edge connected to this junction.
				v.edges.each { |e|
					next if e == edge
					
					#puts i
					#puts e
					#i += 1
					
					# Get extra street data
					street = CG_Street.new(e.material)
					width = (street.width.nil?) ? road_width : street.width / 2
					#puts "> Street Width: #{width.to_mm}"
					
					# Get offset Line objects for this edge.
					offset_lines = self.get_offset_lines(e, v, width)
					offset_line_right = offset_lines[0]
					offset_line_left  = offset_lines[1]
					
					# Check where they intersects.
					intersect_right = Geom.intersect_line_line( base_line_right, offset_line_left )
					intersect_left  = Geom.intersect_line_line( base_line_left,  offset_line_right )
					
					# The intersection will return nil if they are parallel. If this occurs we just
					# use the start point.
					intersect_right = base_line_rev_left[0] if intersect_right.nil?
					intersect_left  = base_line_rev_right[0]  if intersect_left.nil?
					
					# Check the distance from the start point to the intersection.
					len_right = base_line_right[0].distance(intersect_right)
					len_left  = base_line_left[0].distance(intersect_left)
					
					# Pick the closest intersection point.
					# (!) We don't want to pick the closest intersecting. For Right lines we want to
					# pick the intersecting of the line with the smallest angle from the base line 
					# and the one with largest angle for Left lines.
					# > Right
					#if min_len_right.nil? || len_right < min_len_right
					#	min_len_right = len_right
					#	point_right = intersect_right
					#end
					# > Left
					#if min_len_left.nil? || len_left < min_len_left
					#	min_len_left = len_left
					#	point_left = intersect_left
					#end
					
					# Calculate against which pair or edges we round the corners.
					# > Right
					angle = base_line_right[1].tt_angle_between(offset_line_left[1])
					if !angle.nil? && ( right_angle.nil? || angle < right_angle )
						right_angle = angle
						# Get point of the rounded corner
						rounded_points = self.round_corner(corner_radius, minimum_round_angle,
											intersect_right, base_line_right[1], offset_line_left[1])
						point_right = rounded_points
					end
					# > Left
					angle = base_line_left[1].tt_angle_between(offset_line_right[1])
					if !angle.nil? && ( left_angle.nil? || angle > left_angle )
						left_angle = angle
						# Get point of the rounded corner
						rounded_points = self.round_corner(corner_radius, minimum_round_angle,
											intersect_left, base_line_left[1], offset_line_right[1])
						point_left = rounded_points.reverse
					end
				}
				
				# Add points for road face.
				points << point_right unless point_right.nil?
				points << v.position  unless point_right.nil? && point_left.nil?
				points << point_left  unless point_left.nil?
			}
			
			# Draw the road face.
			points.flatten!
			# Debug point order
			#for i in (0..(points.length-1))
			#	model.entities.add_text(i.to_s, points[i], [-10*i,-10*i,20])
			#end
			f = entities.add_face( points )
			f.reverse! if f.normal.z < 0 # Ensure that the face is pointing upwards
			
			return true
		end
		
		
		# Generate Lines for left and righr side of the street.
		# Return array of two Lines.
		def self.get_offset_lines(edge, connection, road_width)
		
			# Starting point and direction of the centre line.
			# Make sure the lines are starting from the opposite side of the connection.
			if edge.start == connection
				p1 = edge.end.position
				p2 = edge.start.position
				vector1 = edge.line[1].reverse
				vector2 = edge.line[1]
			else
				p1 = edge.start.position
				p2 = edge.end.position
				vector1 = edge.line[1]
				vector2 = edge.line[1].reverse
			end
			
			# Move transformation that moves the starting point (p1) by the amount of the road width.
			t_offset = vector1.transform(road_width)
			t_move = Geom::Transformation.translation(t_offset)
			
			# Rotation transformation that will give us a point to the right and the left.
			t_rotate_right1 = Geom::Transformation.rotation(p1, [0,0,1], 270.degrees)
			t_rotate_left1  = Geom::Transformation.rotation(p1, [0,0,1], 90.degrees)
			t_rotate_right2 = Geom::Transformation.rotation(p2, [0,0,1], 90.degrees)
			t_rotate_left2  = Geom::Transformation.rotation(p2, [0,0,1], 270.degrees)
			
			# Right side
			p1_r = p1.transform(t_move)
			p1_r.transform!(t_rotate_right1)
			
			p2_r = p2.transform(t_move)
			p2_r.transform!(t_rotate_right2)
			
			# Left side
			p1_l = p1.transform(t_move)
			p1_l.transform!(t_rotate_left1)
			
			p2_l = p2.transform(t_move)
			p2_l.transform!(t_rotate_left2)
			
			#Sketchup.active_model.entities.add_cpoint(p1_r)
			#Sketchup.active_model.entities.add_cpoint(p1_l)
			#Sketchup.active_model.entities.add_cpoint(p2_r)
			#Sketchup.active_model.entities.add_cpoint(p2_l)
			
			# Compile Lines. [ Point3D, Vector3D ]
			line_r1 = [p1_r, vector1]
			line_l1 = [p1_l, vector1]
			line_r2 = [p2_r, vector2]
			line_l2 = [p2_l, vector2]
			
			return [line_r1, line_l1, line_r2, line_l2]
		end
		
		
		# corner: - point where the two lines intersect
		# line1&2: two lines facing each other.
		def self.round_corner(radius, minimum_angle, corner, line1, line2)
			#puts '> Rounding...'
			
			model = Sketchup.active_model
			sel = model.selection
			
			# We need the average vector between the two lines; the centre point lies along this
			# vector.
			centre_vector = Geom::Vector3d.linear_combination(0.5, line1, 0.5, line2)
			
			# Then we need the angle between and the orientation of the two lines.
			angle = line1.tt_angle_between(line2) # Full orientation of the two lines.
			corner_angle = line1.angle_between(centre_vector) # Local angle between the two lines.
			
			# Don't generate rounded arc for co-linear and lines at a lower angle than the minimum.
			#if angle == 0.0 || angle == 180.degrees || corner_angle < minimum_angle
			if line1.samedirection?(line2) ||
				line1.samedirection?(line2.reverse) ||
				(corner_angle * 2) > (180.degrees - minimum_angle)
				#puts '>> Hard Corner'
				return [corner]
			end
			
			# Get the distance from the intersection to the centre point.
			# c = a csc(A)
			# csc x = 1/sin x
			length = radius * ( 1 / Math.sin(corner_angle) )
			
			# Get the centre point by taking the intersecting point and move by 'length'
			# along 'centre_vector'.
			cv = centre_vector.reverse.normalize.transform(length)
			cm = Geom::Transformation.translation(cv)
			centre = corner.transform(cm)
			
			#model.entities.add_cpoint(centre)
			#model.entities.add_cline(corner, centre)
			
			# Get a 3dpoint offset with the radius from the centre. We will use this to work out the
			# rounded corner points.
			vector = centre_vector.normalize.transform(radius)
			edge_point = centre.offset(vector)
			# Calculate the angle of the arc.
			ratio = radius / length
			arc_angle = Math.acos(ratio)
			# The start and end angle of the arc depends on the full orientaton of the two lines.
			if angle > 180.degrees
				end_angle = 0.0 - arc_angle
			else
				end_angle = arc_angle
			end
			# Calculate all edge corner points
			points = []
			segments = 3
			0.upto(segments) { |i|
				segment_angle = end_angle / 3
				
				tm = Geom::Transformation.rotation(centre, [0,0,1], end_angle - (segment_angle * i) )
				point = edge_point.transform(tm)
				
				points << point
				
				#model.entities.add_cpoint( point )
				#model.entities.add_text(i.to_s, point, [-10*i,-10*i,20])
			}
			return points
		end
		
		
		# Classes
		class CG_Street
			
			attr_accessor(:name, :width)
			
			def initialize(material)
				# (!) Raise error?
				#puts 'init...'
				return nil if not material.kind_of?(Sketchup::Material)
				
				data = material.name.split('_')
				#puts '> split'
				#puts data.inspect
				
				if data.length >= 3 && data[0] == 'CG' && data[1] == 'Street'
					@name = data[2]
					
					#puts '> set name'
					
					if data.length > 3
						#puts '> arguments'
						arguments = data[3, data.length]
						#puts arguments.inspect
						arguments.each { |a|
							d = a.split(':')
							
							case d[0]
								when 'W'
									@width = d[1].to_l
									#puts '> set width'
							end
						}
					end
				end
				#puts '> end'
			end
			
		end
	
	end # module Street_Gen
	
end # module City_Gen


### EXTENDED CLASS METHODS ### ---------------------------------------------------------------------
module Geom
	class Vector3d
		# Return the full orientation of the two lines. Going counter-clockwise.
		def tt_angle_between(vector)
			# self.axes.y -> [0,0,1]
			#puts "\nTT Angle Between"
			
			cross_vector = self * vector
			#direction = (self * vector) % cross_vector.axes.z
			#direction = (self * vector) % cross_vector
			direction = (self * vector) % [0,0,1] # (!) Only works for planar lines?
			#puts '> cross_vector: ' + cross_vector.inspect
			#puts '> cross_vector Z: ' + cross_vector.axes.z.inspect
			#puts '> direction: ' + direction.inspect
			
			angle = self.angle_between(vector)
			
			#puts '> angle: ' + angle.radians.to_s
			
			angle = 360.degrees - angle if direction < 0.0
			
			#puts '> angle: ' + angle.radians.to_s
			return angle
		end
	end
end

#---------------------------------------------------------------------------------------------------
file_loaded('street_gen.rb')