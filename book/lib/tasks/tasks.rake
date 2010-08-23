namespace :custom do
	task :generate, [:file] do |t, args|
		generate = lambda do |source, destination|
			Glyph.info "Generating #{destination}..."
			Glyph.compile Glyph::PROJECT/"text/#{source}.glyph", Glyph::PROJECT/"../#{destination}.textile"
		end
		files = {
			:AUTHORS => :acknowledgement, 
			:CHANGELOG => :changelog, 
			:LICENSE => :license, 
			:README => :introduction
		}
		arg = args[:file].upcase.to_sym
		case arg
		when :ALL then
			files.each_pair { |k,v| generate.call v, k }
		else
			raise RuntimeError, "Unknown file '#{arg}.glyph'" unless files.keys.include? arg
			generate.call files[arg], arg
		end
		Glyph.info "Done."
	end
end
