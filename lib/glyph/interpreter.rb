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

	def evaluate(context, current)
		name = macro_name.text_value
		known_macro = Glyph::MACROS.include? name.to_sym
		element = nil
		parameter = nil
		unless known_macro then
			case 
			when name.match(/^=(.+)/) then
				# Force tag name override if macro starts with a '='
				name.gsub! /^=(.+)/, '\1' 
			when name.match(/^@(.+)/) then
				# Parameter
				name.gsub! /^@(.+)/, '\1' 
				parameter = true
			end
		end
		case
			# Parameter macro
		when parameter then
			element = name
			name = :"|param|"
			# Use XML syntax
		when Glyph['language.set'] == 'xml' then
			element = name
			name = :"|xml|" 
			# Fallback to XML syntax
		when Glyph['language.options.xml_fallback'] then
			unless known_macro then
				element = name
				name = :"|xml|" 
			end
		else
			# Unknown macro
			raise Glyph::SyntaxError, "Undefined macro '#{name}'\n -> source: #{current[:source]}" unless known_macro
		end
		@data = {
			:macro => name.to_sym, 
			:source => context[:source], 
			:document => context[:document], 
			:params => {},
			:info => context[:info]
		}.to_node
		@data[:element] = element if element
		@data[:escape] = true if is_a?(EscapingMacroNode)
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
			@context = context
			@context ||= {:source => '--'}
			@text = text
		end

		def parse
			if @text.match /[^\[\]\|\\\s]+\[/ then
				Glyph.info "  -> Interpreting: #{@context[:source_name]}" if Glyph.debug? && @context[:info] && @context[:source_name]
				@raw = PARSER.parse @text
				tf = PARSER.terminal_failures
				if !@raw.respond_to?(:evaluate) then
					reason = "Incorrect macro syntax"
					err = "#{reason}\n -> #{@context[:source]} [Line #{PARSER.failure_line}, Column #{PARSER.failure_column}]"
					@context[:document].errors << err if @context[:document] && !@context[:embedded]
					raise Glyph::SyntaxError, err
				end
			else
				# Don't bother parsing...
				@raw = @text
			end
			@document = Glyph::Document.new @raw, @context
			@document.inherit_from @context[:document] if @context[:document]
		end

		# @see Glyph::Document#analyze
		def process
			parse unless @raw
			@document.analyze
		end

		# @see Glyph::Document#finalize
		def postprocess
			@document.finalize
		end

		# Returns the finalized @document (calls self#process and self#postprocess if necessary)
		# @return [Glyph::Document] the finalized document
		def document
			parse unless @raw
			return @document if @document.finalized?
			process if @document.new?
			postprocess if @document.analyzed?
			@document
		end

	
	end

end


