#!/usr/bin/env ruby

namespace :generate do

	desc "Process document.glyph"
	task :document => ["load:all"] do
		info "Generating document..."
		text = file_load Glyph::PROJECT/'document.glyph'
		interpreter = Glyph::Interpreter.new text, :source => "file: document.glyph"
		info "Processing..."
		interpreter.process
		info "Post-processing..."
		interpreter.postprocess
		Glyph::DOCUMENT = interpreter.document 
	end

	desc "Create a standalong html file"
	task :html => :document do
		info "Generating HTML file..."
		out = Glyph::PROJECT/"output/html"
		out.mkpath
		file = "#{Glyph::CONFIG.get('document.filename')}.html"
		file_write out/file, Glyph::DOCUMENT.output[:html]
		# TODO: Copy images
	end

end
