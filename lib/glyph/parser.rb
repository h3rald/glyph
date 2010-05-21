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
			if @input.pos < @input.string.length then
				current_char = @input.string[@input.pos].chr
				illegal_delimiter = current_char.match(/\]|\[/) rescue nil
				error "Macro delimiter '#{current_char}' not escaped" if illegal_delimiter
				error "Parsing was not completed"
			end
			@output
		end

		protected

		def parse_contents
			partition_delimiter || escaping_macro || macro || text
		end

		def parse_escaped_contents
			partition_delimiter || escaped_text
		end

		def escaping_macro
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
				while contents = parse_escaped_contents do
					node << contents
				end
				@input.scan(/\=\]/) or error "Escaping macro '#{name}' not closed"		
				aggregate_partitions node
				node
			else
				nil
			end
		end

		def macro
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
				aggregate_partitions node
				node
			else
				nil
			end
		end

		def text
			start_p = @input.pos
			res = @input.scan_until /(\A(\]|\|)|[^\\](\]|\|)|[^\[\]\|\\\s]+\[|\Z)/
			offset = @input.matched.match(/^[^\\](\]|\|)$/) ? 1 : @input.matched.length
			@input.pos = @input.pos - offset rescue @input.pos
			return nil if @input.pos == start_p
			match = @input.string[start_p..@input.pos-1]
			illegal_macro_delimiter? start_p, match
			if match.length > 0 then
				{:type => :text, :value => match}
			else
				nil
			end
		end

		def escaped_text
			start_p = @input.pos
			res = @input.scan_until /(\A(\=\]|\|)|[^\\](\=\]|\|)|\Z)/
			case 
			when @input.matched.match(/^[^\\]\=\]$/) then
				offset = 2
			when @input.matched.match(/^[^\\]\|$/) then
				offset = 1
			else
				offset = @input.matched.length
			end
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

		def partition_delimiter
			if @input.scan(/\|/) then
				unless @current_macro then
					@input.pos = @input.pos-1
					error "Partition delimiter '|' not allowed here"  
				end
				{:partition => true}
			else
				nil
			end
		end

		def aggregate_partitions(node)
			indices = []
			count = 0
			node.children.each do |n|
				indices << count if n[:partition]
				count += 1
			end
			# No partition found
			return false if indices == []
			# Partitions found
			current_index = 0
			save_partition = lambda do |max_index|
				partition = {:type => :partition}.to_node
				current_index.upto(max_index) do |index|
					partition << (node & index)
				end
				node[:partitions] << partition
			end
			indices.each do |i|
				save_partition.call(i-1)
				current_index = i+1
			end
			save_partition.call(node.children.length-1)
			node.children.clear
			node[:partitions]
		end

		def illegal_macro_delimiter?(start_p, string)
			string.match(/\A(\[|\])|[^\\](\[|\])/)
			illegal_delimiter = $1 || $2
			if illegal_delimiter then
				@input.pos = start_p + string.index(illegal_delimiter)
				error "Macro delimiter '#{illegal_delimiter}' not escaped" 
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


