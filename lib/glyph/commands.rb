include GLI


GLI.desc "Enable debugging"
switch [:d, :debug]

GLI.desc 'Create a new Glyph project'
command :init do |c|
	c.action do |global_options,options,args|
		Glyph.run 'project:create', Dir.pwd
	end
end

GLI.desc 'Add a new text file to the project'
arg_name "file_name"
command :add do |c|
	c.action do |global_options,options,args|
		raise ArgumentError, "Please specify a file name." if args.blank?
		Glyph.run 'project:add', args[0]
	end
end

GLI.desc 'Compile the project'
arg_name "[source_file]"
arg_name "[destination_file]"
command :compile do |c|
	c.desc "Specify a glyph file to compile (default: document.glyph)"
	c.flag [:s, :source]
	c.desc "Specify the format of the output file (default: html)"
	c.flag [:f, :format]
	c.desc "Auto-regenerate output on file changes"
	c.switch [:a, :auto]
	c.action do |global_options, options, args|
		raise ArgumentError, "Too many arguments" if args.length > 2
		Glyph.lite_mode = true unless args.blank? 
		Glyph.run! 'load:config'
		original_config = Glyph::CONFIG.dup
		output_targets = Glyph['system.output_targets']
		target = nil
		Glyph['document.output'] = options[:f] if options[:f]
		target = Glyph['document.output']
		target = nil if target.blank?
		target ||= Glyph['filters.target']
		Glyph['document.source'] = options[:s] if options[:s]
		raise ArgumentError, "Output target not specified" unless target
		raise ArgumentError, "Unknown output target '#{target}'" unless output_targets.include? target.to_sym

		# Lite mode
		if Glyph.lite? then
			source_file  = Pathname.new args[0]
			filename = source_file.basename(source_file.extname).to_s
			destination_file = Pathname.new(args[1]) rescue nil
			src_extension = Regexp.escape(source_file.extname) 
			dst_extension = ".#{Glyph['document.output']}"
			destination_file ||= Pathname.new(source_file.to_s.gsub(/#{src_extension}$/, dst_extension))
			raise ArgumentError, "Source file '#{source_file}' does not exist" unless source_file.exist? 
			raise ArgumentError, "Source and destination file are the same" if source_file.to_s == destination_file.to_s
			Glyph['document.filename'] = filename
			Glyph['document.source'] = source_file.to_s
			Glyph['document.output_dir'] = destination_file.parent.to_s # System use only
			Glyph['document.output_file'] = destination_file.basename.to_s # System use only
		end
		begin
			Glyph.run "generate:#{target}"
		rescue Exception => e
			message = e.message
			if Glyph.debug? then
				message << "\n"+"-"*20+"[ Backtrace: ]"+"-"*20
				message << "\n"+e.backtrace.join("\n")
				message << "\n"+"-"*54
			end
			raise RuntimeError, message if Glyph.library?
			Glyph.error message
		end

		# Auto-regeneration
		if options[:a] && !Glyph.lite? then
			Glyph.lite_mode = false
			begin
				require 'directory_watcher'
			rescue LoadError
				raise RuntimeError, "DirectoryWatcher is not available. Install it with: gem install directory_watcher"
			end
			Glyph.info 'Auto-regeneration enabled'
			Glyph.info 'Use ^C to interrupt'
			glob = ['*.glyph', 'config.yml', 'images/**/*', 'lib/**/*', 'snippets.yml', 'styles/**/*', 'text/**/*']
			dw = DirectoryWatcher.new(Glyph::PROJECT, :glob => glob, :interval => 1, :pre_load => true)
			dw.add_observer do |*args|
				puts "="*50
				Glyph.info "Regeneration started: #{args.size} files changed"
				Glyph.reset
				begin
					Glyph.run! "generate:#{target}"
				rescue Exception => e
					Glyph.error e.message
					if Glyph.debug? then
						puts "-"*20+"[ Backtrace: ]"+"-"*20
						puts e.backtrace
						pits "-"*54
					end
				end
			end
			dw.start
			begin
				sleep
			rescue Interrupt
			end
			dw.stop
		end
	end
end

GLI.desc 'Display all project TODO items'
command :todo do |c|
	c.action do |global_options, options, args|
		Glyph['system.quiet'] = true
		Glyph.run "generate:document"
		Glyph['system.quiet'] = false
		unless Glyph.document.todos.blank?
			puts "====================================="
			puts "#{Glyph['document.title']} - TODOs"
			puts "====================================="
			# Group items
			if Glyph.document.todos.respond_to? :group_by then
				Glyph.document.todos.group_by{|e| e[:source]}.each_pair do |k, v|
					puts
					puts "=== #{k} "
					v.each do |i|
						puts " * #{i[:text]}"
					end
				end
			else
				Glyph.document.todos.each do |t|
					Glyph.info t
				end
			end
		else
			Glyph.info "Nothing left to do."
		end
	end
end

GLI.desc 'Display the document outline'
command :outline do |c|
	c.desc "Limit to level N"
	c.flag :l, :level
	c.desc "Show file names"
	c.switch :f, :files
	c.desc "Show titles"
	c.switch :t, :titles
	c.desc "Show IDs"
	c.switch :i, :ids
	c.action do |global_options, options, args|
		levels = options[:l]
		ids = options[:i]
		files = options[:f]
		titles = options[:t]
		titles = true if !ids && !levels && !files || levels && !ids
		Glyph['system.quiet'] = true
		Glyph.run "generate:document"
		Glyph['system.quiet'] = false
		puts "====================================="
		puts "#{Glyph['document.title']} - Outline"
		puts "====================================="
		Glyph.document.structure.descend do |n, level|
			if n.is_a?(Glyph::MacroNode) then
				case
				when n[:name].in?(Glyph['system.structure.headers']) then
					header = Glyph.document.header?(n[:header].code)
					next if !header || levels && header.level-1 > levels.to_i
					last_level = header.level
					h_id = ids ? "[##{header.code}]" : ""
					h_title = titles ? "#{header.title} " : ""
					text = ("  "*(header.level-1))+"- "+h_title+h_id
					puts text unless text.blank?
				when n[:name] == :include then
					if files && n.find_parent{|p| p[:name] == :document && p.is_a?(Glyph::MacroNode)} then
						# When using the book or article macros, includes appear twice: 
						# * in the macro parameters
						# * as children of the document macro
						puts "=== #{n.param(0)}" 
					end
				end	
			end
		end
	end
end

GLI.desc 'Get/set configuration settings'
arg_name "setting [new_value]"
command :config do |c|
	c.desc "Save to global configuration"
	c.switch [:g, :global]
	c.action do |global_options,options,args|
		Glyph.run 'load:config'
		if options[:g] then
			config = Glyph::GLOBAL_CONFIG
		else
			config = Glyph::PROJECT_CONFIG
		end
		case args.length
		when 0 then
			raise ArgumentError, "Too few arguments."
		when 1 then # read current config
			setting = Glyph[args[0]]
			raise RuntimeError, "Unknown setting '#{args[0]}'" if setting.blank?
			Glyph.info setting
		when 2 then
			if args[0].match /^system\..+/ then
				Glyph.warning "Cannot reset '#@value' setting (system use only)."
			else
				# Remove all overrides
				Glyph.config_reset
				# Reload current project config
				config.read 
				config.set args[0], args[1]
				# Write changes to file
				config.write
				# Refresh configuration
				Glyph.config_refresh
			end
		else
			raise ArgumentError, "Too many arguments."
		end
	end
end

pre do |global,command,options,args|
	# Pre logic here
	# Return true to proceed; false to abourt and not call the
	# chosen command
	if global[:d] then
		Glyph.debug_mode = true
	end
	if !command || command.name == :help then
		puts "====================================="
		puts "Glyph v#{Glyph::VERSION}"
		puts "====================================="
	end
	true
end

post do |global,command,options,args|
	# Post logic here
end

on_error do |exception|
	raise if Glyph.library?
	if exception.is_a? Glyph::MacroError then
		exception.display
		false
	else
		if Glyph.debug? then
			Glyph.warning exception.message
			puts "\n"+"-"*20+"[ Backtrace: ]"+"-"*20
			puts "Backtrace:"
			exception.backtrace.each do |b|
				puts b
			end
			Glyph.debug_mode = false
		end
		true
	end
	# Error logic here
	# return false to skip default error handling
end
