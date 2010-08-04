#!/usr/bin/env ruby

namespace :project do
	include Glyph::Utils

	desc "Create a new Glyph project"
	task :create, [:dir] do |t, args|
		dir = Pathname.new args[:dir]
		raise ArgumentError, "Directory #{dir} does not exist." unless dir.exist?
		raise ArgumentError, "Directory #{dir} is not empty." unless dir.children.select{|f| !f.basename.to_s.match(/^(\..+|Gemfile[.\w]*|Rakefile)$/)}.blank?
		# Create subdirectories
		subdirs = ['lib/macros', 'lib/tasks', 'lib/layouts', 'text', 'output', 'images', 'styles']
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
		definitions.map! do |el| 
			element = el
			uniqs.each do |name| 
				if el != name && Glyph.macro_eq?(name, el) && definitions.include?(name) then
					element = name
					break
				end
			end
			element.to_s
		end.uniq!
		c_stats[:definitions] = definitions.sort
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
			files[b.file][:file] = b.file
			files[b.file][:codes] << b.code
			files[b.file][:codes].sort!{|a, b| a.to_s <=> b.to_s}
		end
		c_stats[:files] = files.values.sort{|a, b| a[:file].to_s <=> b[:file].to_s }
		# Check unreferenced bookmarks
		links = get_macros :link
		c_stats[:unreferenced] = c_stats[:codes]-links.map{|l|	l.param(0).to_s.gsub(/^#/, '').to_sym}
	end

	def stats_for_links(c_stats)
		internal = {}
		external = {}
		get_macros(:link).each do |l|
			target = l.parameters[0].to_s
			collection =  target.match(/^#/) ? internal : external
			code = target.gsub(/^#/, '').to_sym
			collection[code] = {:total => 0, :files => {}} unless collection[code]
			coll = collection[code]
			coll[:total] += 1
			files = coll[:files]
			file = (l[:source][:file] rescue Glyph['document.source']).to_sym
			files[file] = 0 if files[file].blank?
			files[file] +=1
		end
		internal_targets = internal.keys.map{|e| "##{e.to_s}" }.sort
		external_targets = external.keys.map{|e| e.to_s}.sort
		c_stats[:internal] = {:details => internal, :targets => internal_targets}
		c_stats[:external] = {:details => external, :targets => external_targets}
	end

	def stats_for_snippets(c_stats)
		snippets = get_macros(:snippet)
		ids = {}
		snippets.each do |s|
			code = s.parameters[0].to_s.to_sym
			ids[code] = {:total => 0, :files => {}} unless ids[code]
			ids[code][:total] += 1
			file = (s[:source][:file] rescue Glyph['document.source'])
			files = ids[code][:files]
			files[file] = 0 if files[file].blank?
			files[file] +=1
		end
		c_stats[:total_instances] = snippets.length
		c_stats[:total_used_definitions] = ids.length
		c_stats[:total_unused_definitions] = Glyph::SNIPPETS.length - ids.keys.length
		c_stats[:unused_definitions] = Glyph::SNIPPETS.keys - ids.keys
		c_stats[:ids] = ids
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
		unless args[:object].blank? then
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
			stats_for_links c_stats
		when :link
			raise ArgumentError, "Please specify a link URL or ID (regexp)" unless args[:value]
			link = args[:value]
			regexp = /#{link}/
			instances = get_macros(:link).select do |l| 
				l.parameters[0].to_s.match regexp
			end.map do |i|
				{:target => i.parameters[0].to_s, :file => (i[:source][:file] rescue Glyph['document.source'])}
			end
			# remove duplicates
			links = []
			instances.each do |i|
				existing = links.select{|s| s == i}[0] rescue nil
				if existing then
					existing[:total] += 1
				else
					i[:total] = 1
					links << i
				end
			end
			Glyph::STATS[:link] = links.sort{|a, b| a[:target] <=> b[:target]}
		when :snippets
			stats_for_snippets c_stats
		when :snippet
			raise ArgumentError, "Please specify a snippet ID" unless args[:value]
			snippet = args[:value].to_sym
			snippets = get_macros(:snippet).select do |l| 
				l.parameters[0].to_s.to_sym == snippet
			end.map do |i|
				i[:source][:file] rescue Glyph['document.source']
			end
			Glyph::STATS[:snippet] = snippets
		else
			# Load all stats
			stats_for_macros stats[:macros]
			stats_for_bookmarks stats[:bookmarks]
			stats_for_links stats[:links]
			stats_for_snippets stats[:snippets]
			stats[:files] = {}
			count_files_in = lambda do |dir|
				files = []
				(Glyph::PROJECT/"#{dir}").find{|f| files << f if f.file? }
				files.length
			end
			stats[:files][:text] = count_files_in.call 'text'
			stats[:files][:lib] = count_files_in.call 'lib'
			stats[:files][:styles] = count_files_in.call 'styles'
			stats[:files][:layouts] = count_files_in.call 'layouts'
			stats[:files][:images] = count_files_in.call 'images'
		end
	end

end
