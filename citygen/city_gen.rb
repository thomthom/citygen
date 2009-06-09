# city_gen.rb
#---------------------------------------------------------------------------------------------------
# Version: 0.1.2a
# Compatible: SketchUp 7 (PC)
#             (other versions untested)
#---------------------------------------------------------------------------------------------------
#
# CHANGELOG
# 0.1.0a - 31.05.2009 (Thom)
#		 * Initial build.
#
# 0.1.1a - 31.05.2009 (Thom)
#		 * Change in the module error checking routine.
#
# 0.1.2a - 31.05.2009 (Thom)
#		 * Added version constant.
#
# 0.1.3a - 31.05.2009 (Thom)
#		 * Updated to the new file structure for use with Tortoise.
#
#---------------------------------------------------------------------------------------------------
#
# KNOWN ISSUES
# * ...
#
#---------------------------------------------------------------------------------------------------
#
# TO-DO / NEXT
# * Add Organizer support
# * Add localization support
#
#---------------------------------------------------------------------------------------------------
#
# CONTRIBUTORS
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
# ...
#
#---------------------------------------------------------------------------------------------------

### DEPENDANCIES ### -------------------------------------------------------------------------------
require 'sketchup.rb'

### MODULES ### ------------------------------------------------------------------------------------
module City_Gen
	
	# CONSTANTS
	unless file_loaded?('city_gen.rb')
		VERSION = '0.1.3'
	end
	
	# VARIABLES
	@menu = UI.menu('Tools').add_submenu('City Generator') unless file_loaded?('city_gen.rb')
	@module_path = Sketchup.find_support_file('citygen/modules/', 'Plugins')
	
	# ACCESSORS
	def self.menu
		@menu
	end
	def self.menu=(value)
		@menu = value
	end
	
	def self.module_path
		@module_path
	end
	def self.module_path=(value)
		@module_path = module_path
	end
	
	### HELPER METHODS ### -------------------------------------------------------------------------
		
	module Helping_Hand
		# Usage:
		# Helping_Hand.start_operation('Operation Name')
		# (do stuff)
		# model.commit_operation
		def self.start_operation(name)
			# Make use of the SU7 speed boost with start_operation while
			# making sure it works in SU6.
			if Sketchup.version.split('.')[0].to_i >= 7
				Sketchup.active_model.start_operation(name, true)
			else
				Sketchup.active_model.start_operation(name)
			end
		end
	end # module Helping_Hand
	
	# MODULES
	# We indicate that this file has now loaded, and try to load the modules.
	file_loaded('city_gen.rb')
	require_all(@module_path)
	
end # module City_Gen