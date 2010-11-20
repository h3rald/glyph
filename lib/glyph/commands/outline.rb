# encoding: utf-8

GLI.desc 'Display the document outline'
command :outline do |c|
	c.desc "Limit to level N"
	c.flag :l, :level
	c.desc "Show file names"
	c.switch :f, :files
	c.desc "Show titles"
	c.switch :t, :titles
	c.desc "Show IDs"
	c.switch :i, :ids
	c.action do |global_options, options, args|
		levels = options[:l]
		ids = options[:i]
		files = options[:f]
		titles = options[:t]
		titles = true if !ids && !levels && !files || levels && !ids
		Glyph['system.quiet'] = true
		Glyph.run "generate:document"
		Glyph['system.quiet'] = false
		puts "====================================="
		puts "#{Glyph['document.title']} - Outline"
		puts "====================================="
		Glyph.document.structure.descend do |n, level|
			if n.is_a?(Glyph::MacroNode) then
				case
				when n[:name].in?(Glyph['system.structure.headers']) then
					header = Glyph.document.header?(n[:header].code) rescue nil
					next if !header || levels && header.level-1 > levels.to_i
					last_level = header.level
					h_id = ids ? "[##{header.code}]" : ""
					h_title = titles ? "#{header.title} " : ""
					text = ("  "*(header.level-1))+"- "+h_title+h_id
					puts text unless text.blank?
				when n[:name] == :include then
					if files && n.find_parent{|p| p[:name] == :document && p.is_a?(Glyph::MacroNode)} then
						# When using the book or article macros, includes appear twice: 
						# * in the macro parameters
						# * as children of the document macro
						puts "=== #{n.param(0)}" 
					end
				end	
			end
		end
	end
end
