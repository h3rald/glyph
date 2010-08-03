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

	#########################
	# Stats -- Helper methods
	# #######################
	
	def stats_for_macros(c_stats)
		macros = get_macros
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
		c_stats
	end

	def stats_for_bookmarks(c_stats)
		bmks = Glyph.document.bookmarks
		c_stats[:codes] = bmks.values.map{|b| b.code}
		c_stats[:codes].sort!{|a, b| a.to_s <=> b.to_s}
		c_stats[:total] = bmks.length
		files = {} 
		bmks.each_value do |b|
			files[b.file] = {:total => 0, :codes => []} unless files[b.file]
			files[b.file][:total] = files[b.file][:total]+1
			files[b.file][:codes] << b.code
			files[b.file][:codes].sort!{|a, b| a.to_s <=> b.to_s}
		end
		c_stats[:files] = files
		# Check unreferenced bookmarks
		links = get_macros :link
		c_stats[:unreferenced] = c_stats[:codes]-links.map{|l|	l.param(0).to_s.gsub(/^#/, '').to_sym}
	end

	def get_macros(name=nil)
		nodes = []
		Glyph.document.structure.descend do |n, level|
			if n.is_a? Glyph::MacroNode then
				nodes << n if !name || Glyph.macro_eq?(name, n[:name])
			end
		end
		nodes
	end



	desc "Display project statistics"
	task :stats, :object, :value, :needs => ["generate:document"]  do |t, args|
		stats = Glyph::STATS
		stats.clear
		# TODO remove
		if args[:object] then
			stats[args[:object]] = {}
			c_stats = stats[args[:object]]
		else
			stats[:macros] = {}
			stats[:bookmarks] = {}
			stats[:links] = {}
			stats[:snippets] = {}
			stats[:files] = {}
		end
		case args[:object]
		when :macros
			stats_for_macros c_stats	
		when :macro
			raise ArgumentError, "Please specify a macro name" unless args[:value]
			name = args[:value].to_sym
			macros = get_macros name
			files = {} 
			macros.each do |n|
				file = n[:source][:file] rescue Glyph['document.source']
				files[file] = 0 unless files[file]
				files[file] = files[file]+1
			end
			c_stats[:total_instances] = macros.length
			c_stats[:files] = files
		when :bookmarks
			stats_for_bookmarks c_stats
		when :bookmark
			raise ArgumentError, "Please specify a bookmark ID" unless args[:value]
			code = args[:value].to_s.gsub(/^#/, '').to_sym
			links = get_macros :link
			references = links.select{|l| l.param(0).to_s.gsub(/^#/, '').to_sym == code}
			c_stats[:file] = Glyph.document.bookmark?(code).file rescue nil
			c_stats[:references] = references.map{|n| n[:source][:file] rescue Glyph['document.source']}
		when :links
		when :link
			raise ArgumentError, "Please specify a link URL (regexp)" unless args[:value]
		when :files
		when :file
			raise ArgumentError, "Please specify a file path" unless args[:value]
		when :snippets
		when :snippet
			raise ArgumentError, "Please specify a snippet ID" unless args[:value]
		else
			# Load all stats
			stats_for_macros stats[:macros]
			stats_for_bookmarks stats[:bookmarks]
		end
	end

end
