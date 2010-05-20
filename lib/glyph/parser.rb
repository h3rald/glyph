# encoding: utf-8
require 'strscan'

module Glyph

	class Parser

		def initialize(text, source_name="--")
			@input = StringScanner.new text
			@output = {:type => :document}.to_node
			@source_name = source_name
			@current_macro = nil
		end

		def parse
			count = 0
			while result = parse_contents do
				@output << result
				count +=1
			end
			@output
		end

		protected

		def parse_contents
			parse_escaping_macro || parse_macro || parse_text
		end

		def parse_escaping_macro
			if @input.scan(/[^\[\]\|\\\s]+\[\=/) then
				name = @input.matched
				name.chop!
				name.chop!
				node = {
					:type => :macro, 
					:name => name.to_sym, 
					:escape => true, 
					:attributes => {}, 
					:partitions => []
				}.to_node
				@current_macro = node
				while contents = parse_escaped_text do
					node << contents
				end
				@input.scan(/\=\]/) or error "Escaping macro '#{name}' not closed"		
				node
			else
				nil
			end
		end

		def parse_macro
			if @input.scan(/[^\[\]\|\\\s]+\[/) then
				name = @input.matched
				name.chop!
				node = {
					:type => :macro, 
					:name => name.to_sym, 
					:escape => false, 
					:attributes => {}, 
					:partitions => []
				}.to_node
				@current_macro = node
				while contents = parse_contents do
					node << contents
				end
				@input.scan(/\]/) or error "Macro '#{name}' not closed"		
				node
			else
				nil
			end
		end

		def parse_text
			start_p = @input.pos
			res = @input.scan_until /\A\]|[^\\]\]|[^\[\]\|\\\s]+\[|\Z/
			offset = @input.matched.match(/^[^\\]\]$/) ? 1 : @input.matched.length
			@input.pos = @input.pos - offset rescue @input.pos
			return nil if @input.pos == start_p
			match = @input.string[start_p..@input.pos-1]
			if match.length > 0 then
				{:type => :text, :value => match}
			else
				nil
			end
		end

		def parse_escaped_text
			start_p = @input.pos
			res = @input.scan_until /\A\=\]|[^\\]\=\]|\Z/
			offset = @input.matched.match(/^[^\\]\=\]$/) ? 2 : @input.matched.length
			@input.pos = @input.pos - offset rescue @input.pos
			return nil if @input.pos == start_p
			match = @input.string[start_p..@input.pos-1]
			illegal_nesting = match.match(/([^\[\]\|\\\s]+)\[\=/)[1] rescue nil
			if illegal_nesting then
				error "Cannot nest escaping macro '#{illegal_nesting}' within escaping macro '#{@current_macro[:name]}'"
			end
			if match.length > 0 then
				{:type => :text, :value => match, :escaped => true}
			else
				nil
			end
		end

		def error(msg)
			lines = @input.string[0..@input.pos].split(/\n/)
			line = lines.length
			column = lines.last.length
			raise Glyph::SyntaxError.new("#{@source_name} [#{line}, #{column}] "+msg)
		end

	end

end


