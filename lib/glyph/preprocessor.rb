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

	# chapter[sec[par[...]]]]:
	#
	# -- current = nil
	# gsn.evaluate
	# Evaluate children
	# mn.evaluate # chapter
	# -- current = context
	# ::: context < chapter
	# -- current = chapter
	# gsn.evaluate # chapter
	# Evaluate chapter children
	# mn.evaluate # sec
	# -- current = chapter
	# ::: context < chapter < sec
	# -- current = sec
	# gsn.evaluate # sec
	# Evaluate sec children
	# mn.evaluate # par
	# -- current = sec
	# ::: context < chapter < sec < par
	# -- current = par

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

		def self.process(text, context={}, print=nil)
			context[:source] ||= ["--"]
			begin
				current = context[:macro] ? context.to_node : nil
				PARSER.parse(text).evaluate context, current
			rescue Exception => e
				raise if e.is_a? MacroError
				if Glyph.testing? then
					raise 
				else
					raise RuntimeError, "An error occurred when preprocessing #{context[:source]}"
				end
			end
		end

		def self.process_document
			context = {:source => ["file: document.glyph"]}.to_node
			process(file_load(Glyph::PROJECT/'document.glyph'), context, true)
			context
			#Glyph::DOCUMENT.from context
		end

		def self.macro(name, &block)
			Glyph::MACROS[name.to_sym] = block			
		end

		def self.macro_alias(new_macro, old_macro)
			Glyph::MACROS[new_macro.to_sym] = Glyph::MACROS[old_macro.to_sym]
		end

	end

end


