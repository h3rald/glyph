module Glyph

	# A Macro object is instantiated by a Glyph::Interpreter whenever a macro is found in the parsed text.
	# The Macro class contains shortcut methods to access the current node and document, as well as other
	# useful methods to be used in macro definitions.
	class Macro

		# Creates a new macro instance from a Node
		# @param [Node] node a node populated with macro data
		def initialize(node)
			@name = node[:macro]
			@node = node
			@value = @node[:value]
			@source = @node[:source]
			esc = '‡‡‡‡‡ESCAPED¤PIPE‡‡‡‡‡'
			@params = @value.gsub(/\\\|/, esc).split('|').map{|p| p.strip.gsub esc, '|'}
		end

		# Raises a macro error
		# @param [String] msg the message to print
		# @raise [MacroError]
		def macro_error(msg)
			raise MacroError.new @node, msg
		end

		# Instantiates a Glyph::Interpreter and interprets a string
		# @param [String] string the string to interpret
		# @return [String] the interpreted output
		# @raise [MacroError] in case of mutual macro inclusion (snippet, include macros)
		def interpret(string)
			@node[:source] = "#{@name}: #{@value}"
			@node[:spawned] = true
			macro_error "Mutual inclusion" if @node.find_parent {|n| n[:source] == @node[:source] }
			Glyph::Interpreter.new(string, @node).document.output
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

		# Executes a macro definition in the context of self
		def execute
			instance_exec(@node, &Glyph::MACROS[@name]).to_s
		end

	end

end
