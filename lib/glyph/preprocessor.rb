#!/usr/bin/env ruby

class GlyphSyntaxNode < Treetop::Runtime::SyntaxNode 

	attr_reader :hashnode

	def evaluate(context, current=nil)
		@hashnode ||= context.to_node
		value = elements.map { |e| e.evaluate(@hashnode, current) if e.respond_to? :evaluate }.join
		escs = [
			['\\]', ']'], 
			['\\[', '['],
			['\\=', '=']
		]
		escs.each{|e| value.gsub! e[0], e[1]}
		value
	end

end 

class MacroNode < GlyphSyntaxNode

	def evaluate(context, current=nil)
		name = macro_name.text_value.to_sym
		raise RuntimeError, "Undefined macro '#{name}'" unless Glyph::MACROS.include? name
		current ||= context.to_node
		@hashnode = context.merge(:macro => name)
		current << @hashnode
		value = super(@hashnode, @hashnode).strip
		@hashnode[:value] = value
		Glyph::MACROS[name].call(@hashnode).to_s
	end

end

class TextNode < GlyphSyntaxNode 

	def evaluate(context, current=nil)
		text_value
	end

end


module Glyph

	module Preprocessor

		extend Actions

		PARSER = ::GlyphLanguageParser.new

		def self.process(text, context={})
			begin
				PARSER.parse(text).evaluate context
			rescue Exception => e
				source = context[:source] ? "'#{context[:source]}'" : ''
				raise if e.is_a? MacroError
				if Glyph.testing? then
					raise 
				else
					raise RuntimeError, "An error occurred when preprocessing #{source}"
				end
			end
		end

		def self.macro(name, &block)
			Glyph::MACROS[name.to_sym] = block			
		end

		def self.macro_alias(new_macro, old_macro)
			Glyph::MACROS[new_macro.to_sym] = Glyph::MACROS[old_macro.to_sym]
		end

	end

end


