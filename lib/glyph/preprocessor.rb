#!/usr/bin/env ruby

class GlyphSyntaxNode < Treetop::Runtime::SyntaxNode 

	def evaluate(context)
		value = elements.map{|e| e.evaluate(context) if e.respond_to? :evaluate }.join
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

	def evaluate(context)
		macro = macro_name.text_value.to_sym
		raise RuntimeError, "Undefined macro '#{macro}'" unless Glyph::MACROS.include? macro
		context[:macro] = (context[:macro]) ? "#{context[:macro]} > #{macro}" : macro
		Glyph::MACROS[macro].call(super(context).strip, context).to_s
	end

end

class TextNode < GlyphSyntaxNode 

	def evaluate(context)
		text_value
	end

end;


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
				raise #RuntimeError, "An error occurred when preprocessing #{source}"
			end
		end

		def self.get_params_from(value)
			esc = '__[=ESCAPED_PIPE=]__'
			value.gsub(/\\\|/, esc).split('|').map{|p| p.strip.gsub esc, '|'}
		end

		def self.macro(name, &block)
			Glyph::MACROS[name.to_sym] = block			
		end

		def self.macro_alias(new_macro, old_macro)
			Glyph::MACROS[new_macro.to_sym] = Glyph::MACROS[old_macro.to_sym]
		end

	end

end


