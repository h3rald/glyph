GLI.desc 'Display statistics'
arg_name "[object(s)] [value]"
command :stats do |c|
	c.action do |global_options, options, args|
		obj = args[0].to_sym rescue nil
		val = args[1]
		Glyph.run! 'project:stats', *[obj, val].compact
		s = Glyph::STATS
		sep = "===== "
		Glyph.info "Collecting statistics..."
		if s[:files] then
			c = s[:files]
			puts sep+'Files:'
			Glyph.info "Text Files: #{c[:text]}"
			Glyph.info "Library Files: #{c[:lib]}"
			Glyph.info "Images: #{c[:images]}"
			Glyph.info "Styles: #{c[:styles]}"
			Glyph.info "Layouts: #{c[:layouts]}"
		end
		if s[:bookmarks] then
			c = s[:bookmarks]
			puts sep+"Bookmarks:"
			Glyph.info "Total: #{c[:total]}"
			Glyph.info "IDs: "+c[:codes].join(", ")
			Glyph.info "Unreferenced: "+c[:unreferenced].join(", ")
			Glyph.info "Files:"
			puts c[:files].map{|e| "   - #{e[:file]} (#{e[:total]}): #{e[:codes].join(', ')}"}
		end
		if s[:bookmark] then
			c = s[:bookmark]
			unless c[:file].blank? then
				puts sep+"Bookmark '#{args[1]}':"
				unref =  c[:references].blank? ? "(unreferenced)" : nil
				Glyph.info "Defined in '#{c[:file]}' #{unref}"
				unless unref then
					Glyph.info "Referenced in:"
					puts c[:references].map{|e| "   - #{e}"}.join("\n")
				end
			else
				Glyph.info "Bookmark '#{args[1]}' is not used in this document"
			end
		end
		if s[:macros] then
			c = s[:macros]
			puts sep+"Macros:"
			Glyph.info "Total Instances: #{c[:total_definitions]}"
			Glyph.info "#{c[:total_definitions]} Definitions Used: "+c[:definitions].join(", ")
		end
		if s[:macro] then
			c = s[:macro]
			if c[:total_instances] > 0 then
				puts sep+"Macro '#{args[1]}'"
				Glyph.info "Total Instances: #{c[:total_instances]}"
				Glyph.info "Files:"
				puts c[:files].to_a.sort.map{|e| "   - #{e[0]} (#{e[1]})"}
			else
				Glyph.info "Macro '#{args[1]}' is not used in this document"
			end
		end
	end
end
