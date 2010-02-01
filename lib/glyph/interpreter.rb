#!/usr/bin/env ruby

class GlyphSyntaxNode < Treetop::Runtime::SyntaxNode 

	attr_reader :hashnode

	def evaluate(context, current=nil)
		current ||= context.to_node
		@hashnode ||= current.to_node
		value = elements.map { |e| e.evaluate(context, current) if e.respond_to? :evaluate }.join 
		escs = [
			['\\]', ']'], 
			['\\[', '['],
			['\\=', '='],
			['\\.', ''],
			['\\\\', '\\']
		]
		escs.each{|e| value.gsub! e[0], e[1]}
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
		Glyph::MACROS[name].call(@hashnode).to_s
	end

end


class TextNode < GlyphSyntaxNode	

	def evaluate(context, current=nil)
		text_value
	end

end


module Glyph

	module Interpreter

		PARSER = ::GlyphLanguageParser.new
		DELAYED_ACTIONS = {}

		def self.process(text, context={})
			node = PARSER.parse(text)
			context[:source] ||= "--"
			text = node.evaluate(context, nil)
			node.hashnode[:output] = text
			node.hashnode
		end

		def self.build_document
			context = {:source => "file: document.glyph"}
			Glyph::DOCUMENT.from process(file_load(Glyph::PROJECT/'document.glyph'), context)
			DELAYED_ACTIONS.each_pair do |key, value|
				Glyph::DOCUMENT[:output].gsub! key.to_s, value.call.to_s 
			end
		end

		def self.macro(name, &block)
			Glyph::MACROS[name.to_sym] = block			
		end

		def self.macro_alias(pair)
			Glyph::MACROS[pair.name.to_sym] = Glyph::MACROS[pair.value.to_sym]
		end

		def self.afterwards(&block)
			ident = block.to_s.to_sym
			DELAYED_ACTIONS[ident] = block
			ident
		end

	end

end


