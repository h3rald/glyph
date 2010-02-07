#!/usr/bin/env ruby

namespace :generate do

	desc "Process source"
	task :document => ["load:all"] do
		info "Generating document from '#{cfg('document.source')}'..."
		text = file_load Glyph::PROJECT/cfg('document.source')
		interpreter = Glyph::Interpreter.new text, :source => "file: #{cfg('document.source')}"
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
		file_write out/file, Glyph::DOCUMENT.output
		# TODO: Copy images
	end

end
