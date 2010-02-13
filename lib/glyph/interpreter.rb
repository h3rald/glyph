#!/usr/bin/env ruby

class GlyphSyntaxNode < Treetop::Runtime::SyntaxNode 

	attr_reader :data

	def evaluate(context, current=nil)
		current ||= context.to_node
		@data ||= current.to_node
		value = elements.map { |e| e.evaluate(context, current) if e.respond_to? :evaluate }.join 
		value
	end

end 


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


class TextNode < GlyphSyntaxNode	

	def evaluate(context, current=nil)
		text_value
	end

end


module Glyph

	class Interpreter

		def initialize(text, context=nil)
			context ||= {:source => '--'}
			@parser = GlyphLanguageParser.new
			@raw = @parser.parse text
			@context = context
			@document = Glyph::Document.new @raw, @context
			@document.inherit_from @context[:document] if @context[:document]
		end

		def process
			@document.analyze
		end

		def postprocess
			@document.finalize
		end

		def document
			return @document if @document.finalized?
			process if @document.new?
			postprocess if @document.analyzed?
			@document
		end

	
	end

end


