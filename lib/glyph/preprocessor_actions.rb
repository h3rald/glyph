#!/usr/bin/env ruby

class MacroError < RuntimeError
	attr_reader :meta
	def initialize(meta, msg)
		@meta = meta
		super("#{@meta[:macro]}(): #{msg}")
	end
end

module Glyph

	module Preprocessor

		module Actions

			def store_id(params, meta)
				ident = params[0].to_sym
				raise MacroError.new(meta, "ID '#{ident}' already exists.") if Glyph::IDS.include? ident
				Glyph::IDS << ident
			end

			def get_snippet(params, meta)
				ident = params[0].to_sym
				raise MacroError.new(meta, "Snippet '#{ident}' does not exist.") unless Glyph::SNIPPETS.include? ident
				Glyph::SNIPPETS[ident]
			end

		end

	end

end
