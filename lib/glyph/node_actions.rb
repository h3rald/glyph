#!/usr/bin/env ruby


module Glyph

	class Node

		def get_params
			esc = '__[=ESCAPED_PIPE=]__'
			self[:value].gsub(/\\\|/, esc).split('|').map{|p| p.strip.gsub esc, '|'}
		end

		def store_id
			params = get_params
			ident = self[:id] || params[0].to_sym
			raise MacroError.new(self, "ID '#{ident}' already exists.") if Glyph::IDS.include? ident
			Glyph::IDS << ident
		end

		def get_snippet
			params = get_params
			ident = params[0].to_sym
			raise MacroError.new(self, "Snippet '#{ident}' does not exist.") unless Glyph::SNIPPETS.include? ident
			Glyph::SNIPPETS[ident]
		end

		def get_title
			params = get_params
			title = params[0]
			level = Glyph::CONFIG.get(:first_heading_level) - 1
			ascend do |n| 
				if [:section, :chapter].include? n[:macro] then
					level+=1
				end
			end
			anchor = params[1] ? params[1] : "t_#{title.gsub(' ', '_')}_#{rand(100)}"
			self[:title] = title
			self[:id] = anchor.to_sym
			self[:level] = level
			store_id
			self
		end

		def load_file
			file = nil
			(Glyph::PROJECT/"text").find do |f|
				file = f if f.to_s.match /\/#{self[:value]}$/
			end	
			raise ArgumentError, "File #{self[:value]} no found." unless file
			file_load file
		end

	end

end
