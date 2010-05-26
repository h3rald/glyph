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
			end
			@output
		end

		protected

		def parse_contents(current)
			escape_sequence(current) || 
				parameter_delimiter(current) || 
				escaping_attribute(current) || 
				escaping_macro(current) || 
				attribute(current) || 
				macro(current) || 
				text(current)
		end

		def parse_escaped_contents(current)
			escape_sequence(current) || parameter_delimiter(current) || escaped_text(current)
		end

		def escaping_macro(current)
			if @input.scan(/[^\[\]\|\\\s]+\[\=/) then
				name = @input.matched
				name.chop!
				name.chop!
				error "#{name}[...] - A macro cannot start with '@' or a digit." if name.match(/^[0-1@]/)
				node = create_node({
					:type => :macro, 
					:name => name.to_sym, 
					:escape => true, 
					:attributes => [], 
					:parameters => []
				})
				while contents = parse_escaped_contents(node) do
					node << contents unless contents[:type] == :attribute
				end
				@input.scan(/\=\]/) or error "Escaping macro '#{name}' not closed"		
				organize_children_for node
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
					:name => name.to_sym
				})
				while contents = parse_escaped_contents(node) do
					node << contents
				end
				current[:attributes] << node
				@input.scan(/\=\]/) or error "Attribute @#{name} not closed"		
				node
			else
				nil
			end
		end

		def macro(current)
			if @input.scan(/[^\[\]\|\\\s]+\[/) then
				name = @input.matched
				name.chop!
				error "#{name}[...] - A macro cannot start with '@' or a digit." if name.match(/^[0-1@]/)
				node = create_node({
					:type => :macro, 
					:escape => false, 
					:name => name.to_sym, 
					:attributes => [], 
					:parameters => []
				})
				while contents = parse_contents(node) do
					node << contents unless contents[:type] == :attribute
				end
				@input.scan(/\]/) or error "Macro '#{name}' not closed"		
				organize_children_for node
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
					:name => name.to_sym
				})
				while contents = parse_contents(node) do
					node << contents
				end
				current[:attributes] << node
				@input.scan(/\]/) or error "Attribute @#{name} not closed"		
				node
			else
				nil
			end
		end

		def text(current)
			start_p = @input.pos
			res = @input.scan_until /(\\.)|(\A(\]|\|)|[^\\](\]|\|)|[^\[\]\|\\\s]+\[|\Z)/
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
			res = @input.scan_until /(\\.)|(\A(\=\]|\|)|[^\\](\=\]|\|)|\Z)/
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
				# Parameters are not allowed outside macros or inside attributes
				if current[:type] == :document || current[:type] == :attribute then
					@input.pos = @input.pos-1
					error "Parameter delimiter '|' not allowed here"  
				end
				create_node :parameter => true
			else
				nil
			end
		end

		def escape_sequence(current)
			if @input.scan(/\\./) then
				create_node :type => :escape, :value => @input.matched, :escaped => true
			end
		end

		def aggregate_parameters_for(node)
			indices = []
			count = 0
			node.children.each do |n|
				indices << count if n[:parameter]
				count += 1
			end
			# No parameter found
			if indices == [] then
				node[:parameters][0] = create_node :type => :parameter, :name => :"0"
				node.children.each do |c|
					node[:parameters][0] << c
				end
			else
				# Parameters found
				current_index = 0
				total_parameters = 0
				save_parameter = lambda do |max_index|
					parameter = create_node :type => :parameter, :name => "#{total_parameters}".to_sym
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
			end
			node[:parameters]
		end

		def organize_children_for(node)
			aggregate_parameters_for node
			node.children.clear
			node[:parameters].each do |p|
				node << p
			end
			empty_parameter = 
				node.children.length == 1 && 
				((node&0).children.length == 0 || 
				 (node&0).children.length == 0 &&
				 (node&0&0)[:type] == :text && 
				 (node&0&0)[:value].blank?)
			node.children.clear if empty_parameter
			node.delete(:parameters)
			node[:attributes].each do |a|
				node << a
			end
			node.delete(:attributes)
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


