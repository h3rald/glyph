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
			occurrences s[:files] if @detailed
		end

		def display_bookmarks
			s = @stats[:bookmarks]
			section :bookmarks
			total :bookmarks, s[:codes].length
			total :referenced_bookmarks, s[:referenced].length
			total :unreferenced_bookmarks, s[:unreferenced].length
			if @detailed then
				inline_list :bookmarks, s[:codes]
				occurrences s[:referenced], "Referenced Bookmarks:"
				inline_list :unreferenced_bookmarks, s[:unreferenced]
				occurrences s[:files] 
			end
		end

		def display_bookmark
			s = @stats[:bookmark]
			b_type = (s[:type] != :bookmark) ? " (#{s[:type]})" : " " 
			section "Bookmark '#{s[:param]}'#{b_type}"
			info "Defined in: #{s[:file]}"
			occurrences s[:references], "Referenced in:" if @detailed 
		end

		def display_snippets
			s = @stats[:snippets]
			section :snippets
			total :snippets, s[:definitions].length
			total :used_snippets, s[:used].length
			total :unused_snippets, s[:unused].length
			if @detailed then
				inline_list :snippets, s[:definitions]
				inline_list :used_snippets, s[:used]
				inline_list :unused_snippets, s[:unused]
				grouped_occurrences s[:used_details], "Usage Details:"
			end
		end

		def display_snippet
			s = @stats[:snippet]
			section "Snippet '#{s[:param]}'"
			total :used_instances, s[:stats][:total]
			occurrences s[:stats][:files], "Usage Details:" if @detailed
		end


		private

		def total(objects, total)
			info "Total #{objects.to_s.title_case}: #{total}"
		end

		def section(name)
			puts "===== #{(name.is_a? Symbol) ? name.to_s.title_case : name}"
		end

		def inline_list(name, arr)
			info "#{name.to_s.title_case}: #{arr.join(', ')}"
		end

		def occurrences(arr, label="Occurrences:")
			info label
			arr.each do |f|
				puts "   - #{f[0]} (#{f[1]})"
			end
		end

		def grouped_occurrences(arr, label="Details:")
			info label
			arr.each do |f|
				puts "   - #{f[0]} (#{f[1][:total]})"
				f[1][:files].each do |i|
					puts "     - #{i[0]} (#{i[1]})"
				end
			end
		end


		


	end
end
