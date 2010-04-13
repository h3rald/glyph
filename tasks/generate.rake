#!/usr/bin/env ruby

namespace :generate do

	desc "Process source"
	task :document => ["load:all"] do
		info "Parsing '#{cfg('document.source')}'..."
		if Glyph.lite? then
			text = Pathname.new cfg('document.source')
		else
			text = file_load Glyph::PROJECT/cfg('document.source')
		end
		interpreter = Glyph::Interpreter.new text, :source => "file: #{cfg('document.source')}"
		info "Processing..."
		interpreter.process
		info "Post-processing..."
		interpreter.postprocess
		Glyph::DOCUMENT = interpreter.document 
	end

	desc "Create a standalone html file"
	task :html => :document do
		info "Generating HTML file..."
		out = Glyph::PROJECT/"output/html"
		out.mkpath
		file = "#{cfg('document.filename')}.html"
		file_write out/file, Glyph::DOCUMENT.output
		info "'#{cfg('document.filename')}.html' generated successfully."
		images = Glyph::PROJECT/'output/html/images'
		images.mkpath
		(Glyph::PROJECT/'images').find do |i|
			if i.file? then
				dest = "#{Glyph::PROJECT/'output/html/images'}/#{i.relative_path_from(Glyph::PROJECT/'images')}"
				Pathname.new(dest).parent.mkpath
				file_copy i.to_s, dest
			end
		end
	end

	desc "Create a pdf file"
	task :pdf => :html do
		info "Generating PDF file..."
		out = Glyph::PROJECT/"output/pdf"
		out.mkpath
		file = cfg('document.filename')
		case cfg('tools.pdf_generator')
		when 'prince' then
			ENV['PATH'] += ";#{ENV['ProgramFiles']}\\Prince\\Engine\\bin" if RUBY_PLATFORM.match /mswin/ 
			res = system "prince #{Glyph::PROJECT/"output/html/#{file}.html"} -o #{out/"#{file}.pdf"}"
			if res then
				info "'#{file}.pdf' generated successfully."
			else
				warning "An error occurred while generating #{file}.pdf"
			end
			# TODO: support other PDF renderers
		else
			warning "Glyph cannot generate PDF. Please specify a valid tools.pdf_generator setting."
		end
	end

end
