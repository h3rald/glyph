# encoding: utf-8

module Glyph
	
	# A Glyph::Interpreter object perform the following actions:
	# * Parses a string of text containing Glyph macros
	# * Creates a document based on the parsed syntax tree
	# * Analyzes and finalizes the document
	class Interpreter

		# Creates a new Glyph::Interpreter object.
		# @param [String] text the string to interpret
		# @param [Hash] context the context to pass along when expanding macros
		def initialize(text, context={})
			@context = context
			@context[:source] ||= {:name => "--", :file => nil, :topic => nil}
			@text = text
			@parser = Glyph::Parser.new text, @context[:source][:name]
		end

		# @see Glyph::Document#analyze
		def process
			parse unless @tree
			@document.analyze
		end

		# @see Glyph::Document#finalize
		def postprocess
			@document.finalize
		end

		# Returns the finalized @document (calls self#process and self#postprocess if necessary)
		# @return [Glyph::Document] the finalized document
		def document
			parse unless @tree
			return @document if @document.finalized?
			process if @document.new?
			postprocess if @document.analyzed?
			@document
		end

		# Parses the string provided during initialization
		# @return [Glyph::SyntaxNode] the Abstract Syntax Tree generated from the string
		# @since 0.3.0
		def parse
			Glyph.info "Parsing: #{@context[:source][:name]}" if Glyph.debug? && @context[:info] && @context[:source][:name]
			@tree = @parser.parse
			@document = Glyph::Document.new @tree, @context
			@document.inherit_from @context[:document] if @context[:document]
			@tree
		end

	end
end


