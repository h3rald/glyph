GLI.desc 'Print Hello, World!'
command :hello do |c|
	c.action do |global_options,options,args|
		puts "Hello, World!"
	end
end
