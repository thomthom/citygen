=begin rdoc
= CityGen
CityGen is the Open Source City Generator for Sketchup.  Please visit the blog at:
citygen.blogger.com
and our project website at:
code.google.com/p/citygen/

== Disclaimer
THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE.

== License
This file is part of CityGen.

CityGen is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

CityGen is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with CityGen.  If not, see <http://www.gnu.org/licenses/>.

== Information
See the citygen folder for further details on how to use this plugin.
=end

require 'sketchup.rb'
require 'extensions.rb'

ext = SketchupExtension.new("CityGen", "citygen/city_gen.rb")
ext.name = "CityGen"
ext.description = "The open source City Generator for SketchUp"
ext.version = "0.1"
ext.creator = "code.google.com/p/citygen"
ext.copyright = "GNU General Public License v3"

Sketchup.register_extension(ext, true)