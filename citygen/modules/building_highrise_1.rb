model = Sketchup.active_model
ents = model.active_entities
building_faces = []
ents.each { |e| building_faces << e if e.typename == "Face" }

def citygen_highrise(fp, min, max, floor)
   Sketchup.active_model.start_operation "", true, true, true
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
end

min = "100m"
max = "500m"
floor = "4m"
citygen_highrise(building_faces, min, max, floor)