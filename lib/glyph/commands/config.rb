# encoding: utf-8

GLI.desc 'Get/set configuration settings'
arg_name "setting [new_value]"
command :config do |c|
	c.desc "Read from/Save to global configuration"
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
			exit_now! "Too few arguments.", -10
		when 1 then # read current config
			setting = Glyph[args[0]]
			exit_now! "Unknown setting '#{args[0]}'", -11 if setting == nil
			Glyph.info setting.inspect
		when 2 then
			if args[0].match /^system\..+/ then
				exit_now! "Cannot reset '#@value' setting (system use only).", -11
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
			exit_now! "Too many arguments.", -12
		end
	end
end
