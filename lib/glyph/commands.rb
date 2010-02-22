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
arg_name "[output_target]"
command :compile do |c|
	c.desc "Specify a glyph file to compile (default: document.glyph)"
	c.flag [:s, :source]
	c.action do |global_options, options, args|
		output_targets = Glyph::CONFIG.get('document.output_targets')
		target = nil
		case args.length
		when 0 then
			target = cfg('document.output')
			target = nil if target.blank?
			target ||= cfg('filters.target')
		when 1 then
			target = args[0]
		else
			raise ArgumentError, "Too many arguments."
		end	
		Glyph.config_override('document.source', options[:s]) if options[:s]
		raise ArgumentError, "Output target not specified" unless target
		raise ArgumentError, "Unknown output target '#{target}'" unless output_targets.include? target.to_sym
		Glyph.run "generate:#{target}"
	end
end

GLI.desc 'Display all project TODO items'
command :todo do |c|
	c.action do |global_options, options, args|
		Glyph.run "generate:document"
		unless Glyph::TODOS.blank?
			info "*** TODOs: ***"
			Glyph::TODOS.each do |t|
				info t
			end
		else
			info "Nothing left to do."
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
			cfg = Glyph::GLOBAL_CONFIG
		else
			cfg = Glyph::PROJECT_CONFIG
		end
		case args.length
		when 0 then
			raise ArgumentError, "Too few arguments."
		when 1 then # read current config
			setting = cfg(args[0])
			raise RuntimeError, "Unknown setting '#{args[0]}'" if setting.blank?
			info Glyph::CONFIG.get(args[0])
		when 2 then
			cfg.set args[0], args[1]
			Glyph.reset_config
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
		Glyph::DEBUG = true
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
	if exception.is_a? MacroError then
		#warning exception.message
		puts exception.message
		false
	else
		if Glyph.const_defined? :DEBUG then
			puts "error: #{exception.message}"
			puts "backtrace:"
			exception.backtrace.each do |b|
				puts b
			end
		end
		true
	end
	# Error logic here
	# return false to skip default error handling
end
