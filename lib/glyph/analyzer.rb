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
			key = @macros_by_def.keys.select{|k| Glyph.macro_eq?(k, name.to_sym) }[0] || name.to_sym
			@macros_by_def[key] = [] unless @macros_by_def[key]
			@macros_by_def[key]
		end

		def with_macros(name=nil, &block)
			raise ArgumentError, "No block given" unless block_given?
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
				existing = @macros_by_def[name] || @macros_by_def[n[:name]]
				if existing then
					existing.each(&block)
				else
					macros = []
					@doc.structure.descend do |n, level|
						if n.is_a?(Glyph::MacroNode) && Glyph.macro_eq?(name, n[:name])
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
			# get macro definitions ()
			c[:definitions] = Glyph::ALIASES[:by_def].keys.sort
			c[:aliases] = Glyph::ALIASES[:by_alias].keys.sort
			c[:instances] = []
			with_macros {|n|  c[:instances] << n[:name]}
			c[:used_definitions] = c[:instances].map{|m| Glyph.macro_definition_for(m) || m}.uniq.sort
		end


	end
end
