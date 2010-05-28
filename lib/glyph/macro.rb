# encoding: utf-8

module Glyph

	# A Macro object is instantiated by a Glyph::Interpreter whenever a macro is found in the parsed text.
	# The Macro class contains shortcut methods to access the current node and document, as well as other
	# useful methods to be used in macro definitions.
	class Macro

		include Validators

		# Creates a new macro instance from a Node
		# @param [Node] node a node populated with macro data
		def initialize(node)
			@node = node
			@name = @node[:name]
			@source = @node[:source] || "--"
		end

		def raw_attributes
			return @raw_attributes if @raw_attributes
			@raw_attributes = {}
			@raw_attributes = @node.attributes
		end

		def raw_parameters
			return @raw_parameters if @raw_parameters
			@raw_parameters = @node.parameters
		end

		def raw_parameter(n)
			raw_parameters[n]
		end

		def raw_attribute(name)
			raw_attributes.select{|n| n[:name] == name}[0]
		end

		def attribute(name)
			return @attributes[name.to_sym] if @attributes && @attributes[name.to_sym]
			return nil unless raw_attribute(name)
			@attributes = {} unless @attributes
			@attributes[name] = raw_attribute(name).evaluate(@node, :attrs => true)
		end

		def parameter(n)
			return @parameters[n] if @parameters && @parameters[n]
			return nil unless raw_parameter(n)
			@parameters = Array.new(raw_parameters.length) unless @parameters
			@parameters[n] = raw_parameter(n).evaluate(@node, :params => true)
		end

		def attributes
			return @attributes if @attributes
			@attributes = {}
			raw_attributes.each do |value|
				@attributes[value[:name]] = value.evaluate(@node, :attrs => true)
			end
			@attributes
		end

		def parameters
			return @parameters if @parameters
			@parameters = []
			raw_parameters.each do |value|
				@parameters << value.evaluate(@node, :params => true)
			end
			@parameters
		end

		alias params parameters
		alias param parameter
		alias attrs attributes
		alias attr attribute
		alias raw_params raw_parameters
		alias raw_param raw_parameter
		alias raw_attrs raw_attributes
		alias raw_attr raw_attribute

		def value
			parameter(0)
		end

		def raw_value
			raw_parameter(0)
		end

		# Returns the "path" to the macro within the syntax tree.
		# @return [String] the macro path
		def path
			macros = []
			@node.ascend do |n|
				case 
				when n.is_a?(Glyph::MacroNode) then
					name = n[:name].to_s
				when n.is_a?(Glyph::ParameterNode) then
					if n.parent.parameters.length == 1 then
						name = nil
					else
						name = n[:name].to_s
					end
				when n.is_a?(Glyph::AttributeNode) then
					name = "@#{n[:name]}"
				else
					name = nil
				end
				macros << name
			end
			macros.reverse.compact.join('/')
		end
		
		# Returns a todo message to include in the document in case of errors.
		# @param [String] message the message to include in the document
		# @return [String] the resulting todo message
		# @since 0.2.0
		def macro_todo(message)
			draft = Glyph['document.draft']
			Glyph['document.draft'] = true unless draft
			res = interpret "![#{message}]"
			Glyph['document.draft'] = false unless draft
			res
		end

		# Raises a macro error (preventing document post-processing)
		# @param [String] msg the message to print
		# @raise [Glyph::MacroError]
		def macro_error(msg, klass=Glyph::MacroError)
			message = "#{msg}\n    source: #{@source}\n    path: #{path}"
			@node[:document].errors << message
			message += "\n    value:\n#{"-"*54}\n#{value.strip}\n#{"-"*54}" if Glyph.debug?
			raise klass, message
		end

		# Prints a macro earning
		# @param [String] msg the message to print
		# @param [Exception] e the exception raised
		# @since 0.2.0
		def macro_warning(msg, e=nil)
			message = "#{msg}\n    source: #{@source}\n    path: #{path}"
			if Glyph.debug? then
				message << %{\n    value:\n#{"-"*54}\n#{value.strip}\n#{"-"*54}} 
				if e then
					message << "\n"+"-"*20+"[ Backtrace: ]"+"-"*20
					message << "\n"+e.backtrace.join("\n")
					message << "\n"+"-"*54
				end
			end
			Glyph.warning message
		end

		# Instantiates a Glyph::Interpreter and interprets a string
		# @param [String] string the string to interpret
		# @return [String] the interpreted output
		# @raise [Glyph::MacroError] in case of mutual macro inclusion (snippet, include macros)
		def interpret(string)
			if @node[:escape] then
				result = string 
			else
				context = {}
				context[:source] = @node[:source] || "#@name[...]"
				context[:embedded] = true
				context[:document] = @node[:document]
				interpreter = Glyph::Interpreter.new string, context
				subtree = interpreter.parse
				@node << subtree
				result = interpreter.document.output
			end
			result.gsub(/\\*([\[\]])/){"\\#$1"}
		end

=begin
		# Encodes all macros in a string so that it can be encoded
		# (and interpreted) later on
		# @param [String] string the string to encode
		# @return [String] the encoded string
		# @since 0.2.0
		def encode(string)
			string.gsub(/([\[\]\|])/) { "‡‡¤#{$1.bytes.to_a[0]}¤‡‡" }
		end

		# Decodes a previously encoded string 
		# so that it can be interpreted
		# @param [String] string the string to decode
		# @return [String] the decoded string
		# @since 0.2.0
		def decode(string)
			string.gsub(/‡‡¤(91|93|124)¤‡‡/) { $1.to_i.chr }
		end
=end

		# @see Glyph::Document#placeholder
		def placeholder(&block)
			@node[:document].placeholder &block
		end			

		# @see Glyph::Document#bookmark
		def bookmark(hash)
			@node[:document].bookmark hash
		end

		# @see Glyph::Document#bookmark?
		def bookmark?(ident)
			@node[:document].bookmark? ident
		end

		# @see Glyph::Document#header?
		def header?(ident)
			@node[:document].header? ident
		end

		# @see Glyph::Document#header
		def header(hash)
			@node[:document].header hash
		end

		# Executes a macro definition in the context of self
		def expand
			block = Glyph::MACROS[@name]
			macro_error "Undefined macro '#@name'}" unless block
			res = instance_exec(@node, &block).to_s
			res.gsub!(/\\*([\[\]\|])/){"\\#$1"} 
			res
		end

		protected

	end

end
