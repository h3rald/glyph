# encoding: utf-8

GLI.desc 'Compile the project'
arg_name "[source_file] [destination_file]"
command :compile do |c|
	c.desc "Specify a glyph file to compile (default: document.glyph)"
	c.flag [:s, :source]
	c.desc "Specify the format of the output file (default: html)"
	c.flag [:f, :format]
	c.desc "Auto-regenerate output on file changes"
	c.switch [:a, :auto]
	c.action do |global_options, options, args|
		exit_now! "Too many arguments", -12 if args.length > 2
		Glyph.lite_mode = true unless args.blank? 
		Glyph.run! 'load:config'
		original_config = Glyph::CONFIG.dup
		output_targets = Glyph['output'].keys
		target = nil
		Glyph['document.output'] = options[:f] if options[:f]
		target = Glyph['document.output']
		target = nil if target.blank?
		target ||= Glyph["output.#{Glyph['document.output']}.filter_target"]
		through = Glyph["output.#{target}.through"]
		Glyph['document.source'] = options[:s] if options[:s]
		if Glyph.multiple_output_files? then
			Glyph["output.#{Glyph['document.output']}.base"] = Glyph::PROJECT/"output/#{Glyph['document.output']}/".to_s if Glyph["output.#{Glyph['document.output']}.base"].blank?
		else
			Glyph["output.#{Glyph['document.output']}.base"] = ""
		end
		exit_now! "Output target not specified", -30 unless target
		exit_now! "Unknown output target '#{target}'", -31 unless output_targets.include? target.to_sym

		# Lite mode
		if Glyph.lite? then
			source_file  = Pathname.new args[0]
			filename = source_file.basename(source_file.extname).to_s
			destination_file = Pathname.new(args[1]) rescue nil
			src_extension = Regexp.escape(source_file.extname) 
			dst_extension = "."+Glyph['document.output']
			destination_file ||= Pathname.new(source_file.to_s.gsub(/#{src_extension}$/, dst_extension))
			exit_now! "Source file '#{source_file}' does not exist", -32 unless source_file.exist? 
			exit_now! "Source and destination file are the same", -33 if source_file.to_s == destination_file.to_s
			Glyph['document.filename'] = filename
			Glyph['document.source'] = source_file.to_s
			Glyph['document.output_dir'] = destination_file.parent.to_s # System use only
			Glyph['document.output_file'] = destination_file.basename.to_s # System use only
		end
		begin
			Glyph.run "generate:#{target}#{through ? "_through_#{through}" : ""}"
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
				exit_now! "DirectoryWatcher is not available. Install it with: gem install directory_watcher", -34
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
