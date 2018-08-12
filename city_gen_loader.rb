require 'sketchup.rb'
require 'extensions.rb'

ext = SketchupExtension.new("CityGen", "citygen/city_gen.rb")
ext.name = "CityGen"
ext.description = "The open source City Generator for SketchUp"
ext.version = "0.1"
ext.creator = "https://github.com/thomthom/citygen"
ext.copyright = "MIT License"

Sketchup.register_extension(ext, true)