#!/usr/bin/env ruby

module Glyph

	class Macro

		def initialize(name, document)
			@document = document
			@name = name.to_sym
		end

		def body(&block)
			@body = block
			Glyph::MACROS[@name] = self
		end

		def placeholder(sym, &block)
			@placeholders[sym] = block
		end

		def __(sym)
			value = @placeholders[sym]
			@document.placeholders[value.to_s] = value
			value.to_s
		end

		def run(node)
			@body.call node
		end

	end

end
