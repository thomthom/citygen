require 'offset'

module City_Gen
  module Bldg_Gen

    #  Convenience Menus for debugging
    menu = City_Gen.menu.add_submenu("Buildings")

    menu.add_item("clf_highrise") { 
      model = Sketchup.active_model
      sel = model.selection
      building_faces = []
      sel.each { |e| building_faces << e if e.typename == "Face" }
      min = "50m"
      max = "500m"
      floor = "4m"
      citygen_highrise(building_faces, min, max, floor)
    }
    menu.add_item("jf_classic") { jf_classic }

    def self.citygen_highrise(fp, min, max, floor)
      Sketchup.active_model.start_operation "", true
      height = 0
      floor_num = 0
      face = []
      face1 = []
      pre_pull = []
      new_ents = []
      fp.each do |e|
	difference = max.to_l - min.to_l
	floor_num = (((rand(difference+1) + min.to_l)/floor.to_l).to_i)
	e.reverse! if e.normal[2] < 0 
	face = e
	face_norm = face.normal
	pre_pull = face.all_connected.to_a
	floor_num.times do
	  face.pushpull floor.to_l, true
	  post_pull = face.all_connected.to_a
	  new_ents = post_pull - pre_pull
	  new_ents.each do |entity|
	    if entity.typename == "Face"
	      face = entity if entity.normal == face_norm
	    end
	  end
	  pre_pull = face.all_connected.to_a
	end
      end
      Sketchup.active_model.commit_operation
    end # clf_highrise



    def self.jf_classic
      min = 300.feet
      max = 1500.feet
      Helping_Hand.start_operation("JF Classic")
      Sketchup.active_model.selection.to_a.each do |face|
	next unless face.is_a? Sketchup::Face
	height = rand(max - min) + min
	half = height / 2
	# Copy original face into a new Group
	g = face.parent.entities.add_group
	face = g.entities.add_face( face.vertices.map{|v| v.position} )
	3.times do |i| 
	  face.reverse! if face.normal.z < 0
	  face.pushpull(half, true)
	  face = (g.entities.to_a - [face]).select{|e| e.is_a?(Sketchup::Face) && e.normal == Z_AXIS}.last
	  face = face.offset(-5.feet) unless i == 2
	  half = half / 2
	end
      end
      Sketchup.active_model.commit_operation
    end # jf_classic

  end # module Bldg_Gen

end # module City_Gen
