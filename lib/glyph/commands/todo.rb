# encoding: utf-8

GLI.desc 'Display all project TODO items'
command :todo do |c|
	c.action do |global_options, options, args|
		Glyph['system.quiet'] = true
		Glyph.run "generate:document"
		Glyph['system.quiet'] = false
		unless Glyph.document.todos.blank?
			puts "====================================="
			puts "#{Glyph['document.title']} - TODOs"
			puts "====================================="
			# Group items
			if Glyph.document.todos.respond_to? :group_by then
				Glyph.document.todos.group_by{|e| e[:source]}.each_pair do |k, v|
					puts
					puts "=== #{k} "
					v.each do |i|
						puts " * #{i[:text]}"
					end
				end
			else
				Glyph.document.todos.each do |t|
					Glyph.info t
				end
			end
		else
			Glyph.info "Nothing left to do."
		end
	end
end
