namespace :custom do
	task :generate, [:file] do |t, args|
		generate = lambda do |source, destination|
			Glyph.info "Generating #{destination}..."
			Glyph.compile Glyph::PROJECT/"text/#{source}.glyph", Glyph::PROJECT/"../#{destination}.textile"
		end
		files = {
			:AUTHORS => :acknowledgements, 
			:CHANGELOG => :changelog, 
			:LICENSE => :license, 
			:README => :introduction
		}
		arg = args[:file].upcase.to_sym
		raise RuntimeError, "Unknown file '#{arg}.glyph'" unless files.keys.include? arg
		generate.call files[arg], arg
		Glyph.info "Done."
	end
end

namespace :generate do
	desc "Create output for h3rald.com integration"
	task :h3rald => [:web] do
		dir = Glyph::PROJECT/'output/h3rald'
		(dir/"glyph/book").mkpath
		# Copy files in subdir
		(dir).find do |i|
			if i.file? then
				next if 
					i.to_s.match(Regexp.escape(dir/'glyph')) || 
					i.to_s.match(Regexp.escape(dir/'images')) || 
					i.to_s.match(Regexp.escape(dir/'styles'))
				dest = dir/"glyph/book/#{i.relative_path_from(Glyph::PROJECT/dir)}"
				src = i.to_s
				Pathname.new(dest).parent.mkpath
				file_copy src, dest
			end
		end
		# Remove files
		dir.children.each do |c|
			unless [dir/'glyph', dir/'images', dir/'styles'].include? c then
				c.directory? ? c.rmtree : c.unlink
			end
		end
		(dir/'images/glyph/glyph.eps').unlink 
		(dir/'images/glyph/glyph.svg').unlink
		# Create project page
		project = Glyph.filter %{layout:project[
				@contents[#{file_load(Glyph::PROJECT/'text/introduction.glyph')}]
			]}
		file_write dir/"glyph.textile", project
	end	
end
