# encoding: utf-8

GLI.desc 'Add a new text file to the project'
arg_name "file_name"
command :add do |c|
	c.action do |global_options,options,args|
		raise ArgumentError, "Please specify a file name." if args.blank?
		Glyph.run 'project:add', args[0]
	end
end
