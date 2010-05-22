# encoding: utf-8
require 'strscan'

module Glyph

	class Parser

		class SyntaxNode < Node; end

		def initialize(text, source_name="--")
			@input = StringScanner.new text
			@output = create_node :type => :document, :name => source_name.to_sym
			@source_name = source_name
			@current_macro = nil
			@current_attribute = nil
		end

		def parse
			count = 0
			while result = parse_contents(@output) do
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

		def parse_contents(current)
			parameter_delimiter(current) || escaping_attribute(current) || escaping_macro(current) || attribute(current) || macro(current) || text(current)
		end

		def parse_escaped_contents(current)
			parameter_delimiter(current) || escaped_text(current)
		end

		def escaping_macro(current)
			if @input.scan(/[^\[\]\|\\\s]+\[\=/) then
				name = @input.matched
				name.chop!
				name.chop!
				node = create_node({
					:type => :macro, 
					:name => name.to_sym, 
					:escape => true, 
					:attributes => {}, 
					:parameters => []
				})
				while contents = parse_escaped_contents(node) do
					node << contents unless contents[:type] == :attribute
				end
				@input.scan(/\=\]/) or error "Escaping macro '#{name}' not closed"		
				aggregate_parameters node
				node
			else
				nil
			end
		end

		def escaping_attribute(current)
			if @input.scan(/@[^\[\]\|\\\s]+\[\=/) then
				error "Attributes cannot be nested" if @current_attribute
				name = @input.matched[1..@input.matched.length-3]
				node = create_node({
					:type => :attribute, 
					:escape => true, 
					:name => "@#{name}".to_sym
				})
				while contents = parse_escaped_contents(node) do
					node << contents
				end
				current[:attributes][name.to_sym] = node
				@input.scan(/\=\]/) or error "Attribute '#{name}' not closed"		
				node
			else
				nil
			end
		end

		def macro(current)
			if @input.scan(/[^\[\]\|\\\s]+\[/) then
				name = @input.matched
				name.chop!
				node = create_node({
					:type => :macro, 
					:name => name.to_sym, 
					:escape => false, 
					:attributes => {}, 
					:parameters => []
				})
				while contents = parse_contents(node) do
					node << contents unless contents[:type] == :attribute
				end
				@input.scan(/\]/) or error "Macro '#{name}' not closed"		
				aggregate_parameters node
				node
			else
				nil
			end
		end

		def attribute(current)
			if @input.scan(/@[^\[\]\|\\\s]+\[/) then
				error "Attributes cannot be nested" if current[:type] == :attribute
				name = @input.matched[1..@input.matched.length-2]
				node = create_node({
					:type => :attribute, 
					:escape => false, 
					:name => "@#{name}".to_sym
				})
				while contents = parse_contents(node) do
					node << contents
				end
				current[:attributes][name.to_sym] = node
				@input.scan(/\]/) or error "Attribute '#{name}' not closed"		
				node
			else
				nil
			end
		end

		def text(current)
			start_p = @input.pos
			res = @input.scan_until /(\A(\]|\|)|[^\\](\]|\|)|[^\[\]\|\\\s]+\[|\Z)/
			offset = @input.matched.match(/^[^\\](\]|\|)$/) ? 1 : @input.matched.length
			@input.pos = @input.pos - offset rescue @input.pos
			return nil if @input.pos == start_p
			match = @input.string[start_p..@input.pos-1]
			illegal_macro_delimiter? start_p, match
			if match.length > 0 then
				create_node :type => :text, :value => match
			else
				nil
			end
		end

		def escaped_text(current)
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
				error "Cannot nest escaping macro '#{illegal_nesting}' within escaping macro '#{current[:name]}'"
			end
			if match.length > 0 then
				create_node :type => :text, :value => match, :escaped => true
			else
				nil
			end
		end

		def parameter_delimiter(current)
			if @input.scan(/\|/) then
				# Segments are not allowed outside macros or inside attributes
				if current[:type] == :document || current[:type] == :attribute then
					@input.pos = @input.pos-1
					error "Segment delimiter '|' not allowed here"  
				end
				create_node :parameter => true
			else
				nil
			end
		end

		def aggregate_parameters(node)
			indices = []
			count = 0
			node.children.each do |n|
				indices << count if n[:parameter]
				count += 1
			end
			# No parameter found
			return false if indices == []
			# Segments found
			current_index = 0
			total_parameters = 0
			save_parameter = lambda do |max_index|
				parameter = create_node :type => :parameter, :name => "|#{total_parameters}|".to_sym
				total_parameters +=1
				current_index.upto(max_index) do |index|
					parameter << (node & index)
				end
				node[:parameters] << parameter
			end
			indices.each do |i|
				save_parameter.call(i-1)
				current_index = i+1
			end
			save_parameter.call(node.children.length-1)
			node.children.clear
			node[:parameters]
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

		def create_node(hash={})
			Glyph::Parser::SyntaxNode.new.merge hash
		end

	end

end


