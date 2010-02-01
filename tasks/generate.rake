#!/usr/bin/env ruby

namespace :generate do

	desc "Process document.glyph"
	task :document => ["load:all"] do
		info "Processing document..."
		Glyph::Interpreter.build_document
	end

	desc "Create a standalong html file"
	task :html => :document do
		info "Generating HTML file..."
		out = Glyph::PROJECT/"output/html"
		out.mkpath
		file = "#{Glyph::CONFIG.get('document.filename')}.html"
		file_write out/file, Glyph::DOCUMENT[:output]
		# TODO: Copy images
	end

end
