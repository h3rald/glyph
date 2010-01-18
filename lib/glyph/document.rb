#!/usr/bin/env ruby

module Glyph

	class Document

		attr_reader :structure, :files

		def initialize
			@segments = []
			@structure = {}.to_tree
		end

		class Segment

			def initialize(file)
				@path = Pathname.new file
				raise RuntimeError, "File '#{file}' does not exist" unless @path.exist?
				@extension = @path.extname.sub /^\./, ''
				@contents = {:raw => file_load(file)}.to_tree
			end

			def get(*format_seq)
				end_seq = format_seq.length-1
				current = 0
				@contents.descend do |c, level|
					if c.name == format_seq[current] then
						return c.value if current == end_seq
						current += 1
					end
				end
				nil
			end

			def convert(source, dest, &block)
				get(source) << {dest => yield(@contents[source], &block)}.to_tree
			end

		end

	end

end
