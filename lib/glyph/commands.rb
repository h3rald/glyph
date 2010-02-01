#!/usr/bin/env ruby

include GLI

alias gli_desc desc # desc is used by Rake as well...

gli_desc 'Create a new Glyph project'
command :init do |c|
	c.action do |global_options,options,args|
		Glyph.run 'project:create', Dir.pwd
	end
end

gli_desc 'Add a new text file to project'
arg_name "file_name"
command :add do |c|
	c.action do |global_options,options,args|
		Glyph.run 'project:add', args[0]
	end
end

gli_desc 'Compile the project'
arg_name "output_target"
command :compile do |c|
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
			raise RuntimeError, "Too many arguments."
		end	
		raise RuntimeError, "Unknown target '#{target}'" unless output_targets.include? target.to_sym
		Glyph.run "generate:#{target}"
		info "'#{cfg('document.filename')}.#{target}' generated successfully."
	end
end

gli_desc 'Get/set configuration settings'
arg_name "setting [new_value]"
command :config do |c|
	c.desc "Save to global configuration"
	c.switch [:g, :global]
	c.action do |global_options,options,args|
		if options[:g] then
			cfg = Glyph::GLOBAL_CONFIG
		else
			cfg = Glyph::PROJECT_CONFIG
		end
		case args.length
		when 0 then
			raise RuntimeError, "Too few arguments."
		when 1 then # read current config
			info Glyph::CONFIG.get(args[0])
		when 2 then
			cfg.set args[0], args[1]
			Glyph.reset_config
		else
			raise RuntimeError, "Too many arguments."
		end
	end
end

pre do |global,command,options,args|
	# Pre logic here
	# Return true to proceed; false to abourt and not call the
	# chosen command
	if !command || command.name == :help then
		puts "Glyph v#{Glyph::VERSION}"
	end
	puts 
	true
end

post do |global,command,options,args|
	# Post logic here
end

on_error do |exception|
	# Error logic here
	# return false to skip default error handling
	true
end
