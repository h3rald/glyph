# encoding: utf-8

require 'strscan'

module Glyph

	# The Glyph::Parser class can parse a string of text containing Glyph macros and produce the
	# corresponding syntax tree.
	# @since 0.3.0
	class Parser

		# Initializes the parser.
		# @param [String] text the text to parse
		# @param [String] source_name the name of the source file (stored in the root node) 
		# @since 0.3.0
		def initialize(text, source_name="--")
			@source_name = source_name || "--"
			@input = StringScanner.new text
			@output = create_node DocumentNode, :name => @source_name.to_sym
			@current_macro = nil
			@current_attribute = nil
		end

		# Parses the string of text provided during initialization
		# @return [Glyph::SyntaxNode] the Abstract Syntax Tree corresponding to the string
		# @since 0.3.0
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
				error "#{name}[=...=] - A macro cannot start with a digit or contain '@'" if (name.match(/^[0-1]/) || name.match(/@/)) && !name.match(/^@:?$/)
				node = macro_node_for name, true
				leaf = node
				node.descend { |n, level| leaf = n }
				while contents = parse_escaped_contents(leaf) do
					leaf << contents unless contents.is_a?(AttributeNode)
				end
				@input.scan(/\=\]/) or error "Escaping macro '#{name}' not closed"		
				organize_children_for leaf
				node
			else
				nil
			end
		end

		def escaping_attribute(current)
			if @input.scan(/@[^:\[\]\|\\\s]+\[\=/) then
				error "Attributes cannot be nested" if @current_attribute
				name = @input.matched[1..@input.matched.length-3]
				node = create_node(AttributeNode, {
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
				error "#{name}[...] - A macro cannot start with a digit or contain '@'" if (name.match(/^[0-1]/) || name.match(/@/)) && !name.match(/^@:?$/)
				node = macro_node_for name 
				leaf = node
				node.descend { |n, level| leaf = n }
				while contents = parse_contents(leaf) do
					leaf << contents unless contents.is_a?(AttributeNode)
				end
				@input.scan(/\]/) or error "Macro '#{name}' not closed"		
				organize_children_for leaf
				node
			else
				nil
			end
		end

		def attribute(current)
			if @input.scan(/@[^:\[\]\|\\\s]+\[/) then
				error "Attributes cannot be nested" if current.is_a?(AttributeNode)
				name = @input.matched[1..@input.matched.length-2]
				node = create_node(AttributeNode, {
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
			match = extract_string(start_p..@input.pos-1)
			illegal_macro_delimiter? start_p, match
			if match.length > 0 then
				create_node TextNode, :value => match
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
			match = extract_string(start_p..@input.pos-1)
			illegal_nesting = match.match(/([^\[\]\|\\\s]+)\[\=/)[1] rescue nil
				if illegal_nesting then
					error "Cannot nest escaping macro '#{illegal_nesting}' within escaping macro '#{current[:name]}'"
				end
				if match.length > 0 then
					create_node TextNode, :value => match, :escaped => true
				else
					nil
				end
		end

		def parameter_delimiter(current)
			if @input.scan(/\|/) then
				# Parameters are not allowed outside macros or inside attributes
				if current.is_a?(DocumentNode) || current.is_a?(AttributeNode) then
					@input.pos = @input.pos-1
					error "Parameter delimiter '|' not allowed here"  
				end
				create_node SyntaxNode, :parameter => true
			else
				nil
			end
		end

		def escape_sequence(current)
			if @input.scan(/\\./) then
				create_node EscapeNode, :value => @input.matched, :escaped => true
			end
		end

		private

		def macro_node_for(ident, escape=false)
			macro_names = ident.split(/\//).select{|e| !e.blank?}
			nest_node = lambda do |parent, count|
				node = create_node(MacroNode, {
					:escape => false, 
					:name => macro_names[count].to_sym
				})
				parent ? (parent&0) << node : parent = node
				if macro_names[count+1] then
					node << create_node(ParameterNode, :name => :"0") 
					nest_node.call(node, count+1)
				else
					node[:parameters] = []
					node[:attributes] = []
					node[:escape] = escape
				end
				node
			end
			nest_node.call(nil, 0)
		end
		
		# Thanks Thomas Leitner
		# http://redmine.ruby-lang.org/issues/show/2645
		def extract_string(range)
			result = nil
			if RUBY_VERSION >= '1.9'
				begin
					enc = @input.string.encoding
					@input.string.force_encoding('ASCII-8BIT')
					result = @input.string[range].force_encoding(enc)
				ensure
					@input.string.force_encoding(enc)
				end
			else
				result = @input.string[range]
			end
			result
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
				node[:parameters][0] = create_node ParameterNode, :name => :"0"
				node.children.each do |c|
					node[:parameters][0] << c
				end
			else
				# Parameters found
				current_index = 0
				total_parameters = 0
				save_parameter = lambda do |max_index|
					parameter = create_node ParameterNode, :name => "#{total_parameters}".to_sym
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
				 (node&0&0).is_a?(TextNode) && 
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

		def create_node(klass, hash={})
			klass.new.from hash
		end

	end

end


