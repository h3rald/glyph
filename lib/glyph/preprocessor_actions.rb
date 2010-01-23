#!/usr/bin/env ruby


module Glyph

	module Preprocessor

		module Actions

			def get_params_from(node)
				esc = '__[=ESCAPED_PIPE=]__'
				node[:value].gsub(/\\\|/, esc).split('|').map{|p| p.strip.gsub esc, '|'}
			end

			def store_id_from(node)
				params = get_params_from node
				ident = params[0].to_sym
				raise MacroError.new(node, "ID '#{ident}' already exists.") if Glyph::IDS.include? ident
				Glyph::IDS << ident
			end

			def get_snippet_from(node)
				params = get_params_from node
				ident = params[0].to_sym
				raise MacroError.new(node, "Snippet '#{ident}' does not exist.") unless Glyph::SNIPPETS.include? ident
				Glyph::SNIPPETS[ident]
			end

		end

	end

end
