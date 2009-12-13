#!/usr/bin/env ruby

namespace :filter do

	desc "Filter source input using Tenjin"
	task :tenjin do |t, args|
		Glyph::SEGMENTS.each do |seg|
			template = Tenjin::Template.new seg.file.to_s
			template.convert
			rep = template.render # TODO: context...
			seg.add_rep :tenjin, rep if Glyph.phase == :parsing
		end
	end

end
