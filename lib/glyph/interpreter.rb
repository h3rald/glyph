# @private
class GlyphSyntaxNode < Treetop::Runtime::SyntaxNode 

	attr_reader :data

	def evaluate(context, current=nil)
		current ||= context.to_node
		@data ||= current.to_node
		value = elements.map { |e| e.evaluate(context, current) if e.respond_to? :evaluate }.join 
		value
	end

end 

# @private
class MacroNode < GlyphSyntaxNode

	def evaluate(context, current=nil)
		name = macro_name.text_value.to_sym
		raise RuntimeError, "Undefined macro '#{name}'" unless Glyph::MACROS.include? name
		@data = {:macro => name, :source => context[:source], :document => context[:document]}.to_node
		current << @data
		value = super(context, @data).strip 
		@data[:value] = value
		Glyph::Macro.new(@data).execute
	end

end

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

		# Creates a new Glyph::Interpreter object.
		# @param [String] text the string to interpret
		# @param [Hash] context the context to pass along when evaluating macros
		def initialize(text, context=nil)
			context ||= {:source => '--'}
			@parser = GlyphLanguageParser.new
			@raw = @parser.parse text
			@context = context
			tf = @parser.terminal_failures
			if !@raw.respond_to?(:evaluate) then
				reason = "Syntax Error: Missing delimiter?"
				line = @parser.failure_line
				column = @parser.failure_column
				location = @parser.input[@parser.index...@parser.failure_index]
				raise RuntimeError, "#{reason}\n -> #{@context[:source]} [Line #{line}, Column #{column}]"
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


