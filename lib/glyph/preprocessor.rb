#!/usr/bin/env ruby

module Glyph

	class MacroLanguageParser
		DOC = {} # Document Tree
	end

	module Preprocessor

		extend Actions


		def self.process(text, info={})
			parser = MacroLanguageParser.new
			# TODO
		end

		def self.run(m, params, meta)
			raise RuntimeError, "Undefined macro '#{m}'" unless Glyph::MACROS.include? m.to_sym
			Glyph::MACROS[m.to_sym].call params, meta
		end

		def self.macro(name, &block)
			Glyph::MACROS[name.to_sym] = block			
		end

		def self.macro_alias(new_macro, old_macro)
			Glyph::MACROS[new_macro.to_sym] = Glyph::MACROS[old_macro.to_sym]
		end

	end

end


