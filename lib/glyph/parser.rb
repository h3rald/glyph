# encoding: utf-8
require 'strscan'

module Glyph

	class Parser

		def initialize(text)
			@input = StringScanner.new text
			@output = {:type => :document}.to_node
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
			parse_macro || parse_text
		end


		def parse_macro
			if @input.scan(/[^\[\]\|\\\s]+\[/) then
				name = @input.matched
				name.chop!
				node = {:type => :macro, :name => name.to_sym, :escape => false, :params => {}, :order => []}.to_node
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
			res = @input.scan_until /\]|[^\[\]\|\\\s]+\[|\Z/
				@input.pos = @input.pos - @input.matched.length rescue @input.pos
			return nil if @input.pos == start_p
			match = @input.string[start_p..@input.pos-1]
			if match.length > 0 then
				{:type => :text, :value => match}
			else
				nil
			end
		end

		def error(msg)
			raise Glyph::SyntaxError.new(msg)
		end

	end

end


