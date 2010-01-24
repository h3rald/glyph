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

			def get_title_from(node)
				title = node[:value]
				level = Glyph::CONFIG.get(:first_heading_level) - 1
				node.ascend do |n| 
					if [:section, :chapter].include? n[:macro] then
						level+=1
					end
				end
				[title, level]
			end

			def load_file_from(node)
				file = nil
				(Glyph::PROJECT/"text").find do |f|
					file = f if f.to_s.match /\/#{node[:value]}$/
				end	
				raise ArgumentError, "File #{node[:value]} no found." unless file
				file_load file
			end

		end

	end

end
