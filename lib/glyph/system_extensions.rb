#!/usr/bin/env ruby

module Kernel

	def info(message)
		puts " ->  #{message}" unless Glyph::CONFIG.get :quiet
	end

	def warning(message)
		puts " [!] #{message}" unless Glyph::CONFIG.get :quiet
	end

end
