# @private
class GlyphSyntaxNode < Treetop::Runtime::SyntaxNode 

	attr_reader :data

	def evaluate(context, current=nil)
		current ||= context.to_node
		@data ||= current.to_node
		elements.map { |e| e.evaluate(context, current) if e.respond_to? :evaluate }.join 
	end

end

# @private
class MacroNode < GlyphSyntaxNode

	def evaluate(context, current=nil)
		name = macro_name.text_value.to_sym
		raise Glyph::SyntaxError, "Undefined macro '#{name}'\n -> source: #{current[:source]}" unless Glyph::MACROS.include? name
		@data = {:macro => name, :source => context[:source], :document => context[:document]}.to_node
		@data[:escape] = true if is_a? EscapingMacroNode
		current << @data
		@data[:value] = super(context, @data).strip
		Glyph::Macro.new(@data).execute
	end

end

# @private
class EscapingMacroNode < MacroNode; end

# @private
class TextNode < GlyphSyntaxNode	

	def evaluate(context, current=nil)
		text_value
	end

end


module Glyph

	# A Glyph::Interpreter object perform the following actions:
	# * Parses a string of text containing Glyph macros
	# * Creates a document based on the parsed syntax tree
	# * Analyzes and finalizes the document
	class Interpreter

		PARSER = GlyphLanguageParser.new

		# Creates a new Glyph::Interpreter object.
		# @param [String] text the string to interpret
		# @param [Hash] context the context to pass along when evaluating macros
		def initialize(text, context=nil)
			context ||= {:source => '--'}
			@raw = PARSER.parse text
			@context = context
			tf = PARSER.terminal_failures
			if !@raw.respond_to?(:evaluate) then
				reason = "Incorrect macro syntax"
				err = "#{reason}\n -> #{@context[:source]} [Line #{PARSER.failure_line}, Column #{PARSER.failure_column}]"
				@context[:document].errors << err if @context[:document] && !@context[:embedded]
				raise Glyph::SyntaxError, err
			end
			@document = Glyph::Document.new @raw, @context
			@document.inherit_from @context[:document] if @context[:document]
		end

		# @see Glyph::Document#analyze
		def process
			@document.analyze
		end

		# @see Glyph::Document#finalize
		def postprocess
			@document.finalize
		end

		# Returns the finalized @document (calls self#process and self#postprocess if necessary)
		# @return [Glyph::Document] the finalized document
		def document
			return @document if @document.finalized?
			process if @document.new?
			postprocess if @document.analyzed?
			@document
		end

	
	end

end


