#!/usr/bin/env ruby
#
namespace :project do

	desc "Creates a new Glyph project in the specified (empty) directory"
	task :create, [:dir] do |t, args|
		dir = Pathname.new args[:dir]
		raise ArgumentError, "Directory #{dir} does not exist." unless dir.exist?
		raise ArgumentError, "Directory #{dir} is not empty." unless dir.children.blank?
		# Create subdirectories
		subdirs = ['tasks', 'config', 'lib', 'source', 'output']
		subdirs.each {|d| (dir/d).mkdir }
		# Create files
		# TODO
		info "Project '#{dir.basename}' created successfully."
	end

end
