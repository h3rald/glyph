#!/usr/bin/env ruby

namespace :project do
	include Glyph::Utils

	desc "Create a new Glyph project"
	task :create, [:dir] do |t, args|
		dir = Pathname.new args[:dir]
		raise ArgumentError, "Directory #{dir} does not exist." unless dir.exist?
		raise ArgumentError, "Directory #{dir} is not empty." unless dir.children.select{|f| !f.basename.to_s.match(/^(\..+|Gemfile[.\w]*|Rakefile)$/)}.blank?
		# Create subdirectories
		subdirs = ['lib/tasks', 'lib/macros', 'lib/macros', 'lib', 'text', 'output', 'images', 'styles', 'lib/layouts']
		subdirs.each {|d| (dir/d).mkpath }
		# Create snippets
		yaml_dump Glyph::PROJECT/'snippets.yml', {:test => "This is a \nTest snippet"}
		# Create files
		file_copy Glyph::HOME/'document.glyph', Glyph::PROJECT/'document.glyph'
		config = yaml_load Glyph::HOME/'config.yml'
	 	config[:document][:filename] = dir.basename.to_s
	 	config[:document][:title] = dir.basename.to_s
		config[:document][:author] = ENV['USER'] || ENV['USERNAME'] 	
		config.delete(:system)
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

	desc "Display project statistics"
	task :stats, :object, :value, :parameter, :needs => ["generate:document"]  do |t, args|
		stats = Glyph::STATS
		stats[:macros] = {}
		stats[:bookmarks] = {}
		stats[:links] = {}
		stats[:snippets] = {}
		stats[:files] = {}
		stats[:global] = {}
		get_macros = lambda do |name|
			nodes = []
			Glyph.document.structure.descend do |n, level|
				if n.is_a? Glyph::MacroNode then
					nodes << n if !name || Glyph.macro_eq?(name, n[:name])
				end
			end
			nodes
		end
		c_stats = args[:object] ? stats[args[:object]] : stats[:all]
		case args[:object]
		when :macros
			macros = get_macros.call nil
			c_stats[:total_instances] = macros.length			
			definitions = macros.map{|n| n[:name] }.uniq
			uniqs = definitions.dup
			definitions.delete_if do |el| 
				found = false
				uniqs.each do |name| 
					if Glyph.macro_eq? name, el then
						found = true
						break
					end
				end
			end
			c_stats[:definitions] = definitions
			c_stats[:total_definitions] = definitions.length
		when :macro
		when :bookmarks
		when :bookmark
		when :links
		when :topics
		when :snippets
		when :snippet
		else
		end
	end

end
