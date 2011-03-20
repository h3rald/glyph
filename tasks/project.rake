#!/usr/bin/env ruby

namespace :project do
	include Glyph::Utils

	desc "Create a new Glyph project"
	task :create, [:dir] do |t, args|
		dir = Pathname.new args[:dir]
		raise ArgumentError, "Directory #{dir} does not exist." unless dir.exist?
		raise ArgumentError, "Directory #{dir} is not empty." unless dir.children.select{|f| !f.basename.to_s.match(/^(\..+|Gemfile[.\w]*|Rakefile)$/)}.blank?
		# Create subdirectories
		subdirs = ['lib/macros', 'lib/tasks', 'lib/layouts', 'lib/tasks', 'lib/commands', 'text', 'output', 'images', 'styles']
		subdirs.each {|d| (dir/d).mkpath }
		# Create files
		file_copy Glyph::HOME/'document.glyph', Glyph::PROJECT/'document.glyph'
		config = yaml_load Glyph::HOME/'config.yml'
		config[:document][:filename] = dir.basename.to_s
		config[:document][:title] = dir.basename.to_s
		config[:document][:author] = ENV['USER'] || ENV['USERNAME'] 	
		config.each_pair { |k, v| config.delete(k) unless k == :document }
		yaml_dump Glyph::PROJECT/'config.yml', config
		info "Project '#{dir.basename}' created successfully."
	end

	desc "Add a new text file to the project"
	task :add, [:file] do |t, args|
		Glyph.enable 'project:add'
		file = Glyph::PROJECT/"text/#{args[:file]}" 
		file.parent.mkpath
		raise ArgumentError, "File '#{args[:file]}' already exists." if file.exist?
		File.new(file.to_s, "w").close
	end
end


