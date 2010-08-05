module Glyph
	class Analyzer

		include Glyph::Utils

		attr_reader :stats

		def initialize(doc=Glyph.document)
			@doc = doc
			@stats = {}
			@macros = []
			@macros_by_def = {}
		end

		def macro_array_for(name)
			return @macros_by_def[name.to_sym] if @macros_by_def[name.to_sym]
			key = @macros_by_def.keys.select{|k| macro_eq?(k, name.to_sym) }[0] || name.to_sym
			@macros_by_def[key] = [] unless @macros_by_def[key]
			@macros_by_def[key]
		end

		def with_macros(name=nil, &block)
			raise ArgumentError, "No block given" unless block_given?
			name = name.to_sym if name
			if !name then
				unless @macros.blank? then
					@macros.each(&block)
				else
					@doc.structure.descend do |n, level|
						if n.is_a?(Glyph::MacroNode)
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
						if n.is_a?(Glyph::MacroNode) && macro_eq?(name, n[:name])
							macros << n
							block.call n
						end
					end
					@macros_by_def[name] = macros
				end
			end
		end	

		def stats_for(stats_type, *args)
			send :"stats_#{stats_type}", *args
		end

		protected

		def stats_macros
			c = @stats[:macros] = {}
			c[:definitions] = Glyph::ALIASES[:by_def].keys.sort
			c[:aliases] = Glyph::ALIASES[:by_alias].keys.sort
			c[:instances] = []
			with_macros {|n|  c[:instances] << n[:name]}
			c[:used_definitions] = c[:instances].map{|m| macro_definition_for(m) || m}.uniq.sort
		end

		def stats_macro(name)
			name = name.to_sym
			raise ArgumentError, "Unknown macro '#{name}'" unless Glyph::MACROS.include? name
			c = @stats[:macro] = {}
			c[:instances] = []
			c[:alias_for] = macro_definition_for name 
			files = {}
			with_macros(name) do |n|
				c[:instances] << n[:name]
				files[n.source_file] ||= 0
			 	files[n.source_file]	+= 1
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
			c[:files] = files.to_a.sort
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
			c[:file] = bmk.file.to_s
			c[:type] = bmk.is_a?(Glyph::Header) ? :header : :anchor
			c[:references] = []
			with_macros(:link) do |n|
				target = n.parameters[0][:value].to_s.gsub(/^#/, '').to_sym
				c[:references] << n.source_file unless c[:references].include? n.source_file
			end
			c[:references].sort!
		end


	end
end
