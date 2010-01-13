#!/usr/bin/env ruby

module Glyph

	module Preprocessor

		PARAM_REGEX = "[^()]*(?:@\(.*\))*[^()]*"
		MACRO_REGEX = /([^()\s]+)\((#{PARAM_REGEX}(?:\|#{PARAM_REGEX})*)\)/m 

		extend Actions

		def self.process(text, info={})
			text.gsub(MACRO_REGEX) do |m|
				# Note: pipes (|) cannot be escaped; use &#124; instead.
				begin
					meta = {:macro => $1}.merge info
					m = run($1, $2.split('|').map{|e| e.strip}, meta).strip.gsub(/@\((.*)\)/, '\1')
				rescue Exception => e
					raise
					warning e
				end
				m
			end
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


