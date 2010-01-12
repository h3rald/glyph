#!/usr/bin/env ruby

module Glyph

	module Preprocessor

		PARAM_REGEX = "[^()]*(?:@\(.*\))*[^()]*"
		MACRO_REGEX = /([^()\s]+)\((#{PARAM_REGEX}(?:\|#{PARAM_REGEX})*)\)/ 

		def self.process(text)
			text.gsub(MACRO_REGEX) do |m|
				# Note: pipes (|) cannot be escaped; use &#124; instead.
				begin
					m = run($1, $2.split('|'))
				rescue Exception => e
					warning e
				end
				m
			end
		end

		def self.run(m, params)
			raise RuntimeError, "Undefined macro '#{m}'" unless Glyph::MACROS.include? m.to_sym
			Glyph::MACROS[m.to_sym].call params
		end

		def self.macro(name, &block)
			Glyph::MACROS[name.to_sym] = block			
		end

		def self.macro_alias(new_macro, old_macro)
			Glyph::MACROS[new_macro.to_sym] = Glyph::MACROS[old_macro.to_sym]
		end

	end

end
