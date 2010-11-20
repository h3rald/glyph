# encoding: utf-8

GLI.desc 'Create a new Glyph project'
command :init do |c|
	c.action do |global_options,options,args|
		Glyph.run 'project:create', Dir.pwd
	end
end
