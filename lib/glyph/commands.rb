include GLI

desc 'Describe some switch here'
switch [:s,:switch]

desc 'Describe some flag here'
default_value 'the default'
arg_name 'The name of the argument'
flag [:f,:flagname]

desc 'Create a new Glyph project'
command :init do |c|
	c.action do |global_options,options,args|
		Glyph.run 'project:create', Dir.pwd
	end
end

desc 'Describe compile here'
arg_name 'Describe arguments to compile here'
command :compile do |c|
	c.action do |global_options,options,args|
	end
end

pre do |global,command,options,args|
	# Pre logic here
	# Return true to proceed; false to abourt and not call the
	# chosen command
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

