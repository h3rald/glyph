module Glyph
	class Reporter

		include Glyph::Utils

		attr_accessor :detailed

		def initialize(stats)
			@stats = stats
			@detailed = true
		end

		def display
			[:files, :macros, :snippets, :bookmarks, :links, 
				:macro, :snippet, :bookmark, :link].each do |s|
				send :"display_#{s}" unless @stats[s].blank?
			end
		end

		protected

		def display_macros
			s = @stats[:macros]
			section :macros
			total :macro_instances, s[:instances].length
			total :macro_definitions, s[:definitions].length
			total :macro_aliases, s[:aliases].length
			total :used_macro_definitions, s[:used_definitions].length
			if @detailed then
				inline_list :macro_definitions, s[:definitions]
				inline_list :used_macro_definitions, s[:used_definitions] 
			end
		end

		def display_macro
			s = @stats[:macro]
			alias_for = s[:alias_for] ? " (alias for: #{s[:alias_for]})" : " "
			section "Macro '#{s[:param]}'#{alias_for}"
			total :instances, s[:instances].length
			file_occurrences s[:files] if @detailed
		end

		private

		def total(objects, total)
			Glyph.info "Total #{objects.to_s.title_case}: #{total}"
		end

		def section(name)
			puts "===== #{(name.is_a? Symbol) ? name.to_s.title_case : name}"
		end

		def inline_list(name, arr)
			Glyph.info "#{name.to_s.title_case}: #{arr.join(', ')}"
		end

		def file_occurrences(files)
			Glyph.info "Occurrences:"
			files.sort{|a,b| a[1] <=> b[1]}.each do |f|
				puts "   - #{f[0]} (#{f[1]})"
			end
		end

		


	end
end
