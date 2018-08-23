require 'sketchup.rb'

module City_Gen
  module StreetGenerator

    def self.generate
      model = Sketchup.active_model
      model.start_operation('Generate Streetmap')

      entities = model.entities
      entities.clear!

      w = 200.m
      h = 100.m

      boundary = [
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(w, 0, 0),
        Geom::Point3d.new(w, h, 0),
        Geom::Point3d.new(0, h, 0),
      ]
      boundary.each_with_index { |pt, i|
        entities.add_cpoint(pt)
        j = ((i + 1) % boundary.size)
        pt2 = boundary[j]
        entities.add_cline(pt, pt2)
      }

      # City Center
      r1 = 0.6
      r2 = 1.0 - r1
      r2h = r2 / 2.0
      x = (w * r2h) + rand(w * r1)
      y = (h *r2h) + rand(h * r1)
      center = Geom::Point3d.new(x, y, 0)
      entities.add_cpoint(center)

      # Main streets
      num_streets = 3
      last_angle = 0.0
      min_angle_between = 25.degrees.to_f
      available_angle_range = 360.degrees - (min_angle_between * num_streets)
      angle_per_street = available_angle_range / num_streets
      puts
      puts
      puts "min_angle_between: #{min_angle_between.radians}"
      puts "available_angle_range: #{available_angle_range.radians}"
      puts "angle_per_street: #{angle_per_street.radians}"
      puts
      num_streets.times { |i|
        r = 360.degrees.to_f / num_streets
        d = r / 3.0
        a = (r * i) + ( rand(d) - (d / 2.0) )
        angle = a

        tr = Geom::Transformation.rotation(ORIGIN, Z_AXIS, angle)
        pt2 = Geom::Point3d.new(1, 0, 0).transform(tr)
        direction = ORIGIN.vector_to(pt2).normalize
        puts angle.radians
        last_angle = angle

        next unless direction.valid?
        end_pt = self.main_street(entities, center, direction, boundary)
        entities.add_text("#{i}", end_pt, [1,1,0])
      }

    ensure
      model.commit_operation
    end

    def self.main_street(entities, center, direction, boundary)
      bounds = Geom::BoundingBox.new
      bounds.add(boundary)
      pt1 = center
      pt2 = pt1
      10.times { |i|
        length = 5.m + rand(25.m)

        pt2 = pt1.offset(direction, length)

        angle = rand(10.degrees) - 5.degrees
        tr = Geom::Transformation.rotation(pt1, Z_AXIS, angle)
        pt2.transform!(tr)

        entities.add_line(pt1, pt2)
        break unless bounds.contains?(pt2)

        pt1 = pt2
      }
      pt2
    end

    unless file_loaded?(__FILE__)
      cmd = UI::Command.new('Generate Streetmap') {
        self.generate
      }
      cmd_generate = cmd

      City_Gen.menu.add_item(cmd_generate)

      toolbar = UI::Toolbar.new('CityGen')
      toolbar.add_item(cmd_generate)
      toolbar.restore

      file_loaded(__FILE__)
    end

  end
end