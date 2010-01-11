#!/usr/bin/env ruby

include GLI

alias gli_desc desc # desc is used by Rake as well...

gli_desc 'Create a new Glyph project'
arg_name "project_name"
command :init do |c|
	c.action do |global_options,options,args|
		Glyph.run 'project:create', Dir.pwd
	end
end

gli_desc 'Add a new text file to project'
arg_name "project_name"
command :add do |c|
	c.action do |global_options,options,args|
		Glyph.run 'project:add', args[0]
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
		case
		when args.length == 0 then
			raise RuntimeError, "Too few arguments."
		when args.length == 1 then # read current config
			info Glyph::CONFIG.get(args[0])
		when args.length == 2 then
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
