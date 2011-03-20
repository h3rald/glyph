# encoding: utf-8

module Glyph

	# @since 0.4.0
	# This class is used to collect statistics about a Glyph document.
	class Analyzer

		include Glyph::Utils

		attr_reader :stats

		# Initializes a new Analyzer
		# @param [Glyph::Document] doc the document to analyze
		def initialize(doc=Glyph.document)
			@doc = doc
			@stats = {}
			@macros = []
			@macros_by_def = {}
		end

		# Helper method used to return an array of specific macro instances
		# @param [String, Symbol] name the name of the macro definition
		def macro_array_for(name)
			return @macros_by_def[name.to_sym] if @macros_by_def[name.to_sym]
			key = @macros_by_def.keys.select{|k| macro_eq?(k, name.to_sym) }[0] || name.to_sym
			@macros_by_def[key] = [] unless @macros_by_def[key]
			@macros_by_def[key]
		end

		# Iterator over specific macro instances
		# @param [String, Symbol] name the name of the macro definition (if left blank, iterates over all macro instances)
		# @yieldparam [Glyph::MacroNode] n the macro node
		def with_macros(name=nil, &block)
			raise ArgumentError, "No block given" unless block_given?
			name = name.to_sym if name
			if !name then
				unless @macros.blank? then
					@macros.each(&block)
				else
					@doc.structure.descend do |n, level|
						if n.is_a?(Glyph::MacroNode) && n.source
							@macros << n
							macro_array_for(n[:name]) << n
							block.call n
						end
					end
				end
			else
				existing = @macros_by_def[name]
				if existing then
					existing.each(&block)
				else
					macros = []
					@doc.structure.descend do |n, level|
						if n.is_a?(Glyph::MacroNode) && macro_eq?(name, n[:name]) && n.source
							macros << n
							block.call n
						end
					end
					@macros_by_def[name] = macros
				end
			end
		end	

		# Retrieves statistics of a given type
		# @param [String, Symbol] stats_type the type of stats to retrieve 
		# (:macros, :bookmarks, :links, :snippets, :files, :global, :macro, :bookmark, :snippet, :link)
		# @param [String, Symbol] *args Stats parameter(s) (e.g. a macro name, bookmark ID, etc.)
		def stats_for(stats_type, *args)
			begin
				send :"stats_#{stats_type}", *args 
			rescue NoMethodError => e
				raise RuntimeError, "Unable to calculate #{stats_type} stats"
			end
		end

		protected

		def stats_global
			stats_macros
			stats_bookmarks
			stats_links
			stats_snippets
			stats_files
		end

		def stats_macros
			c = @stats[:macros] = {}
			c[:aliases] = Glyph::ALIASES[:by_alias].keys.sort
			c[:definitions] = (Glyph::MACROS.keys - c[:aliases]).uniq.sort
			c[:instances] = []
			with_macros {|n|  c[:instances] << n[:name]}
			c[:used_definitions] = c[:instances].map{|m| macro_definition_for(m) || m}.uniq.sort
		end

		def stats_macro(name)
			name = name.to_sym
			raise ArgumentError, "Unknown macro '#{name}'" unless Glyph::MACROS.include? name
			c = @stats[:macro] = {}
			c[:param] = name
			c[:instances] = []
			c[:alias_for] = macro_definition_for name 
			files = {}
			with_macros(name) do |n|
				unless n.source.blank? then	
					c[:instances] << n[:name]
					files[n.source] ||= 0
					files[n.source]	+= 1
				end
			end
			raise ArgumentError, "Macro '#{name}' is not used in this document" if c[:instances].blank?
			if c[:alias_for] && !name.in?(c[:instances]) then
				raise ArgumentError, "Macro '#{name}' is not used in this document, did you mean '#{c[:alias_for]}'?" 
			end
			c[:files] = files.to_a.sort
		end

		def stats_bookmarks
			c = @stats[:bookmarks] = {}
			c[:codes] = []
			files = {}
			@doc.bookmarks.each_pair do |k, v|
				c[:codes] << k
				files[v.file] ||= 0
				files[v.file] +=1
			end
			c[:codes].sort!
			referenced = {}
			with_macros(:link) do |n|
				target =n.parameters[0][:value].to_s
				if target.match(/^#/) then
					code = target.gsub(/^#/, '').to_sym 
					referenced[code] ||= 0
					referenced[code] += 1	
				end
			end
			c[:referenced] = referenced.to_a.sort
			c[:unreferenced] = c[:codes] - c[:referenced].map{|e| e[0]}
		end

		def stats_bookmark(name)
			code = name.to_s.gsub(/^#/, '').to_sym
			raise ArgumentError, "Bookmark '#{code}' does not exist" unless @doc.bookmark? code
			c = @stats[:bookmark] = {}
			bmk = @doc.bookmark? code
			c[:param] = name
			c[:definition] = bmk.definition.to_s
			c[:file] = bmk.file.to_s
			c[:type] = bmk.is_a?(Glyph::Header) ? :header : :anchor
			references = {}
			with_macros(:link) do |n|
				target = n.parameters[0].to_s.gsub(/^#/, '').to_sym
				count_occurrences_for references, target, n if target == code
			end
			c[:references]= references[code][:files] rescue []
		end

		def stats_links
			c = @stats[:links] = {}
			internal = {}
			external = {}
			with_macros(:link) do |n|
				target = n.parameters[0].to_s
				collection =  target.match(/^#/) ? internal : external
				#code = target.gsub(/^#/, '').to_sym
				count_occurrences_for collection, target, n
			end
			c[:internal] = internal.to_a.sort
			c[:external] = external.to_a.sort
		end

		def stats_link(name)
			regexp = /#{name}/ 
				links = {}
			with_macros(:link) do |n|
				target = n.parameters[0].to_s
				if target.match regexp then
					count_occurrences_for links, target, n
				end
			end
			raise ArgumentError, "No link matching /#{name}/ was found" if links.blank?
			@stats[:link] = {}
			@stats[:link][:stats] = links.to_a.sort 
			@stats[:link][:param] = name 
		end

		def stats_snippets
			c = @stats[:snippets] = {}
			snippets = {}
			c[:definitions] = @doc.snippets.keys.sort
			c[:values] = @doc.snippets
			c[:used] = []
			c[:unused] = []
			c[:total] = 0
			with_macros(:snippet) do |n|
				code = n.parameters[0].to_s.to_sym
				c[:used] << code unless c[:used].include? code
				c[:total] += 1
				#count_occurrences_for snippets, code, n
			end
			#c[:used_details] = snippets.to_a.sort
			c[:used].sort!
			c[:unused] = (c[:definitions] - c[:used]).sort
		end

		def stats_snippet(name)
			name = name.to_sym
			snippets = {}
			raise ArgumentError, "Snippet '#{name}' does not exist" unless @doc.snippet? name
			with_macros(:snippet) do |n|
				code = n.parameters[0].to_s.to_sym
				if code == name then
					count_occurrences_for snippets, code, n
				end
			end
			raise ArgumentError, "Snippet '#{name}' is not used in this document" if snippets.blank?
			@stats[:snippet] = {}
			@stats[:snippet][:stats] = snippets[name]
			@stats[:snippet][:param] = name
		end

		def stats_files
			@stats[:files] = {}
			count_files_in = lambda do |dir|
				files = []
				(Glyph::PROJECT/"#{dir}").find{|f| files << f if f.file? } rescue nil
				files.length
			end
			@stats[:files][:text] = count_files_in.call 'text'
			@stats[:files][:lib] = count_files_in.call 'lib'
			@stats[:files][:styles] = count_files_in.call 'styles'
			@stats[:files][:layouts] = count_files_in.call 'layouts'
			@stats[:files][:images] = count_files_in.call 'images'
		end

		private

		def count_occurrences_for(collection, code, n)
			collection[code] ||= {:total => 0, :files =>[]} unless collection[code]
			collection[code][:total] += 1
			coll = collection[code][:files]
			added = false
			coll.each do |file|
				if file[0] == n.source then
					file[1] += 1
					added = true
					break
				end
			end
			coll << [n.source, 1] unless added
			coll.sort!
		end

	end
end
