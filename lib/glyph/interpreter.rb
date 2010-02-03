#!/usr/bin/env ruby

class GlyphSyntaxNode < Treetop::Runtime::SyntaxNode 

	attr_reader :hashnode

	def evaluate(context, current=nil)
		current ||= context.to_node
		@hashnode ||= current.to_node
		value = elements.map { |e| e.evaluate(context, current) if e.respond_to? :evaluate }.join 
		value
	end

end 


class MacroNode < GlyphSyntaxNode

	def evaluate(context, current=nil)
		name = macro_name.text_value.to_sym
		raise RuntimeError, "Undefined macro '#{name}'" unless Glyph::MACROS.include? name
		@hashnode = {:macro => name, :source => context[:source]}.to_node
		current << @hashnode
		value = super(context, @hashnode).strip 
		@hashnode[:value] = value
		Glyph::MACROS[name].run(@hashnode).to_s
	end

end


class TextNode < GlyphSyntaxNode	

	def evaluate(context, current=nil)
		text_value
	end

end


module Glyph

	class Interpreter

		PARSER = ::GlyphLanguageParser.new

		def initialize(text, context=nil)
			context ||= {:source => '--'}
			@raw = PARSER.parse text
			@context = context
		end

		def preprocess
			@document = Glyph::Document.new @raw, @context
			@document.scan
		end

		def process(format)
			@document.analyze format
		end

		def postprocess(format)
			@document.postprocess format
		end

		def self.macro(name, &block)
			Glyph::MACROS[name.to_sym] = block			
		end

		def self.macro_alias(pair)
			Glyph::MACROS[pair.name.to_sym] = Glyph::MACROS[pair.value.to_sym]
		end

	end

end


