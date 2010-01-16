#!/usr/bin/env ruby


module Glyph

	module Preprocessor

		module Actions

			def store_id(params, context)
				ident = params[0].to_sym
				raise MacroError.new(context, "ID '#{ident}' already exists.") if Glyph::IDS.include? ident
				Glyph::IDS << ident
			end

			def get_snippet(params, context)
				ident = params[0].to_sym
				raise MacroError.new(context, "Snippet '#{ident}' does not exist.") unless Glyph::SNIPPETS.include? ident
				Glyph::SNIPPETS[ident]
			end

		end

	end

end
