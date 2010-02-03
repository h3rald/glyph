#!/usr/bin/env ruby

module Glyph

	class Macro

		def initialize(name)
			@pre = nil
			@body = nil
			@post = nil
		end

		def placeholder
			@post.to_s
		end

		def run(*params)
			value = @body.call params
			value ||= placeholder
			value
		end

		def prerun(*params)
			@pre.call params
		end

		def postrun(*params)
			@post.call params
		end

		def pre(&block)
			@pre = block
		end

		def post(&block)
			@post = block
		end

		def body(&block)
			@body = nil
		end
	end

end
