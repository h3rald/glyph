GLI.desc 'Generates one or more specific files required for Glyph releases'
arg_name "file_name"
command :generate do |c|
	c.action do |global_options,options,args|
		if args.blank? then
			raise RuntimeError, "You must specify a file to generate or 'all'"
		else
			Glyph.run 'custom:generate', args[0]
		end
	end
end
