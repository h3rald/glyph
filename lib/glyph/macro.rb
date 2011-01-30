# encoding: utf-8

module Glyph

	# A Macro object is instantiated by a Glyph::Interpreter whenever a macro is found in the parsed text.
	# The Macro class contains shortcut methods to access the current node and document, as well as other
	# useful methods to be used in macro definitions.
	class Macro

		include Validators
		include Utils

		attr_reader :node, :source_name, :source_file, :source_topic, :name

		# Creates a new macro instance from a Node
		# @param [Node] node a node populated with macro data
		def initialize(node)
			@data = {}
			@node = node
			@name = @node[:name]
			@updated_source = nil
			@source_name = @node[:source][:name] || nil rescue "--"
			@source_topic = @node[:source][:topic] || nil rescue "--"
			@source_file = @node[:source][:file] rescue nil
		end

		# Resets the name of the updated source (call before calling 
		# Macro#interpret)
		# @param [String] name the source name
		# @param [String] file the source file
		# @param [String] topic the topic file
		# @since 0.3.0
		def update_source(name, file=nil, topic=nil)
			file ||= @node[:source][:file] rescue nil
			@updated_source = {:name => name, :file => file, :topic => topic}
		end
		
		# Returns a Glyph code representation of the specified parameter
		# @param [Fixnum] n the index of the parameter
		# @return [String, nil] the string representation of the parameter
		# @since 0.3.0
		def raw_parameter(n)
			@node.parameter(n).contents.to_s rescue nil
		end

		# Returns a Glyph code representation of the specified attribute
		# @param [String, Symbol] name the name of the attribute
		# @return [String, nil] the string representation of the attribute
		# @since 0.3.0
		def raw_attribute(name)
			@node.attribute(name).contents.to_s rescue nil
		end

		# Returns an evaluated macro attribute by name
		# @param [String, Symbol] name the name of the attribute
		# @param [Hash] options a hash of options
		# @option options [Boolean] :strip whether the value is stripped or not
		# @return [String, nil] the value of the attribute
		# @since 0.3.0
		def attribute(name, options={:strip => true, :null_if_blank => true})
			return @attributes[name.to_sym] if @attributes && @attributes[name.to_sym]
			return nil unless @node.attribute(name)
			@attributes = {} unless @attributes
			@attributes[name] = @node.attribute(name).evaluate(@node, :attrs => true).to_s
			@attributes[name].strip! if options[:strip]
			@attributes[name] = nil if @attributes[name].blank? && options[:null_if_blank]
			@attributes[name]
		end

		# Returns an evaluated macro parameter by index
		# @param [Fixnum] n the index of the parameter
		# @param [Hash] options a hash of options
		# @option options [Boolean] :strip whether the value is stripped or not
		# @return [String, nil] the value of the parameter
		# @since 0.3.0
		def parameter(n, options={:strip => true, :null_if_blank => true})
			return @parameters[n] if @parameters && @parameters[n]
			return nil unless @node.parameter(n)
			@parameters = Array.new(@node.parameters.length) unless @parameters
			@parameters[n] = @node.parameter(n).evaluate(@node, :params => true).to_s
			@parameters[n].strip! if options[:strip]
			@parameters[n] = nil if @parameters[n].blank? && options[:null_if_blank]
			@parameters[n]
		end

		# Returns a hash containing all evaluated macro attributes
		# @param [Hash] options a hash of options
		# @option options [Boolean] :strip whether the value is stripped or not
		# @return [Hash] the macro attributes
		# @since 0.3.0
		def attributes(options={:strip => true, :null_if_blank => true})
			return @attributes if @attributes
			@attributes = {}
			@node.attributes.each do |value|
				@attributes[value[:name]] = value.evaluate(@node, :attrs => true)
				@attributes[value[:name]].strip! if options[:strip]
				@attributes[value[:name]] = nil if @attributes[value[:name]].blank? && options[:null_if_blank]
			end
			@attributes
		end

		# Returns an array containing all evaluated macro parameters
		# @param [Hash] options a hash of options
		# @option options [Boolean] :strip whether the value is stripped or not
		# @return [Array] the macro parameters
		# @since 0.3.0
		def parameters(options={:strip => true, :null_if_blank => true})
			return @parameters if @parameters
			@parameters = []
			@node.parameters.each do |value|
				@parameters << value.evaluate(@node, :params => true)
				@parameters[@parameters.length-1].strip! if options[:strip]
				@parameters[@parameters.length-1] = nil if @parameters.last.blank? && options[:null_if_blank]
			end
			@parameters
		end

		alias params parameters
		alias param parameter
		alias attrs attributes
		alias attr attribute
		alias raw_param raw_parameter
		alias raw_attr raw_attribute

		# Equivalent to Glyph::Macro#parameter(0).
		# @since 0.3.0
		def value
			parameter(0)
		end

		# Equivalent to Glyph::Macro#raw_parameter(0).
		# @since 0.3.0
		def raw_value
			raw_parameter(0)
		end

		# Returns the "path" to the macro within the syntax tree.
		# @return [String] the macro path
		# @since 0.3.0
		def path
			macros = []
			@node.ascend do |n|
				case 
				when n.is_a?(Glyph::MacroNode) then
					if n[:name] == :"|xml|" then
						name = "xml[#{n[:element]}]"
					else
						break if n[:name] == :include
						name = n[:name].to_s
					end
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
			@node[:document].errors << msg if @node[:document]
			raise klass.new(msg, self)
		end

		# Prints a macro earning
		# @param [String] msg the message to print
		# @param [Exception] e the exception raised
		# @since 0.2.0
		def macro_warning(msg, e=nil)
			if e.is_a?(Glyph::MacroError) then
				e.display 
			else
				message = "#{msg}\n    source: #{@source_name}\n    path: #{path}"
				if Glyph.debug? then
					message << %{\n#{"-"*54}\n#{@node.to_s.gsub(/\t/, ' ')}\n#{"-"*54}} 
					if e then
						message << "\n"+"-"*20+"[ Backtrace: ]"+"-"*20
						message << "\n"+e.backtrace.join("\n")
						message << "\n"+"-"*54
					end
				end
				Glyph.warning message
			end
		end

		# Instantiates a Glyph::Interpreter and interprets a string
		# @param [String] string the string to interpret
		# @return [String] the interpreted output
		def interpret(string)
			@node[:escape] ? string : inject(string).document.output
		end

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

		# @since 0.5.0
		# Renders a macro representation
		# @param [Symbol, String] rep the representation to render
		# @param [Hash] data the data to pass to the representation
		def render(rep=nil, data=nil)
			rep ||= @name
			data ||= @data
			block = Glyph::REPS[rep.to_sym]
			macro_error "No macro representation for '#{rep}'", e unless block
			instance_exec(data, &block).to_s
		end

		# TODO: docs
		def dispatch(&block)
			@node[:dispatch] = block
			value
		end

		# TODO: docs
		def apply(text)
			body = text.dup
			# Parameters
			body.gsub!(/\{\{(\d+)\}\}/) do
				raw_param($1.to_i).to_s.strip
			end
			# Attributes
			body.gsub!(/\{\{([^\[\]\|\\\s]+)\}\}/) do
				raw_attr($1.to_sym).to_s.strip
			end
			interpret body
		end

		# TODO: docs
		def inject(string)
			context = create_context
			interpreter = Glyph::Interpreter.new string, context
			subtree = interpreter.parse
			subtree[:source] = context[:source]
			@node << subtree
			interpreter
		end

		# TODO: docs
		def parse(string)
			Glyph::Interpreter.new(string, create_context).parse
		end

		# TODO: docs
		def parse_quoted_string(string)
			parse(string.gsub(/\\([\]\[\|=])/, '\1'))&0
		end


		# Executes a macro definition in the context of self
		def expand
			block = Glyph::MACROS[@name]
			macro_error "Undefined macro '#@name'" unless block
			res = instance_exec(@node, &block).to_s
			res.gsub!(/\\?([\[\]\|])/){"\\#$1"} 
			res
		end

		private

		def create_context
			context = {}
			context[:source] = @updated_source || @node[:source]
			context[:embedded] = true
			context[:document] = @node[:document]
			context
		end

	end
end
