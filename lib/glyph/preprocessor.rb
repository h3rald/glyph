#!/usr/bin/env ruby

module Glyph

	module Preprocessor

		PARAM_REGEX = "[^()]*(?:@\(.*\))*[^()]*"
		MACRO_REGEX = /([^()\s])\((#{PARAM_REGEX}(?:\|#{PARAM_REGEX})*)\)/ 
		
		def process(text)
			text.gsub(MACRO_REGEX) do |m|
				# Note: pipes (|) cannot be escaped; use &#124; instead.
				m.replace macro($1, $2.split('|'))
			end
		end

		def macro(macro, *params)
			raise RuntimeError, "Undefined macro '#{macro}'" unless Glyph::MACROS.include? macro
			Glyph::MACROS[macro].run
		end

	end

end
