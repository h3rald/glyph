#!/usr/bin/env ruby

class GlyphSyntaxNode < Treetop::Runtime::SyntaxNode 

	attr_reader :hashnode

	def evaluate(context, current=nil, print=false)
		current ||= context.to_node
		@hashnode ||= current.to_node
		value = elements.map { |e| e.evaluate(context, current, print) if e.respond_to? :evaluate }.join 
		escs = [
			['\\]', ']'], 
			['\\[', '['],
			['\\=', '=']
		]
		escs.each{|e| value.gsub! e[0], e[1]}
		value
	end

end 

class QualifiedNode < GlyphSyntaxNode; end

class MacroNode < QualifiedNode

	def evaluate(context, current=nil, print=false)
		name = macro_name.text_value.to_sym
		raise RuntimeError, "Undefined macro '#{name}'" unless Glyph::MACROS.include? name
		@hashnode = {:macro => name, :source => context[:source]}.to_node
		current << @hashnode
		if print then
			puts "---"
			puts "hashnode: #{@hashnode[:macro]}"
			puts "current: #{current[:macro]}" 
			current.children.each {|c| puts " -> #{c[:macro]}"}
		end
		value = super(context, @hashnode, print).strip 
		@hashnode[:value] = value
		Glyph::MACROS[name].call(@hashnode).to_s
	end

end


class TextNode < QualifiedNode 

	def evaluate(context, current=nil, print=false)
		text_value
	end

end


module Glyph

	module Preprocessor

		extend Actions

		PARSER = ::GlyphLanguageParser.new

		def self.process(text, context={})
			analyze(text, context)[:output]
		end

		def self.analyze(text, context={}, print=false)
			begin
				node = PARSER.parse(text)
				context[:source] ||= "--"
				text = node.evaluate(context, nil, print)
				node.hashnode[:output] = text
				node.hashnode
			rescue Exception => e
				raise if e.is_a? MacroError
				if Glyph.testing? then
					raise 
				else
					raise RuntimeError, "An error occurred when preprocessing #{context[:source]}"
				end
			end
		end

		def self.build_document
			context = {:soure => "file: document.glyph"}
			Glyph::DOCUMENT.from analyze(file_load(Glyph::PROJECT/'document.glyph'), context)
		end

		def self.macro(name, &block)
			Glyph::MACROS[name.to_sym] = block			
		end

		def self.macro_alias(new_macro, old_macro)
			Glyph::MACROS[new_macro.to_sym] = Glyph::MACROS[old_macro.to_sym]
		end

	end

end


