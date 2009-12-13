#!/usr/bin/env ruby

module Glyph

	class Segment
		
		attr_reader :current, :reps, :filters, :ext,:file

		def initialize(pathname)
			@file = pathname
			@filters = []
			@reps = {}
			@ext = pathname.extname
			read_file
		end

		def add_rep(filter, output)
			raise RuntimeError, "Filter '#{filter}' was already applied." if filter.in? @filters 
			@current = @reps[filter] = output
			@filters << filter
		end

		private

		def read_file
			raise ArgumentError, "File '#@file' does not exist." unless @file.exist?
			raise RuntimeError, "File '#@file' cannot be read." unless @file.readable?
			@reps[:raw] = @file.read
		end

  end

end
