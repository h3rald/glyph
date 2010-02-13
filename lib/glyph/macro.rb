#!/usr/bin/env ruby

module Glyph

	class Macro

		def initialize(node)
			@name = node[:macro]
			@node = node
			@value = @node[:value]
			@source = @node[:source]
			esc = '‡‡‡‡‡ESCAPED¤PIPE‡‡‡‡‡'
			@params = @value.gsub(/\\\|/, esc).split('|').map{|p| p.strip.gsub esc, '|'}
		end

		def macro_error(msg)
			raise MacroError.new @node, msg
		end

		def interpret(string)
			@node[:source] = "#{@name}: #{@value}"
			macro_error "Mutual inclusion" if @node.find_parent {|n| n[:source] == @node[:source] }
			Glyph::Interpreter.new(string, @node).document.output
		end

		def placeholder(&block)
			@node[:document].placeholder &block
		end			

		def bookmark(hash)
			@node[:document].bookmark hash
		end

		def bookmark?(ident)
			@node[:document].bookmark? ident
		end

		def header?(ident)
			@node[:document].header? ident
		end

		def header(hash)
			@node[:document].header hash
		end

		def execute
			instance_exec(@node, &Glyph::MACROS[@name]).to_s
		end

	end

end
