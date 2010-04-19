#!/usr/bin/env ruby

namespace :generate do

	desc "Process source"
	task :document => ["load:all"] do
		Glyph.info "Parsing '#{Glyph['document.source']}'..."
		if Glyph.lite? then
			text = file_load Pathname.new(Glyph['document.source'])
		else
			text = file_load Glyph::PROJECT/Glyph['document.source']
		end
		interpreter = Glyph::Interpreter.new text, :source => "file: #{Glyph['document.source']}"
		Glyph.info "Processing..."
		interpreter.process
		Glyph.info "Post-processing..."
		interpreter.postprocess
		Glyph.document = interpreter.document
	end

	desc "Create a standalone html file"
	task :html => :document do
		Glyph.info "Generating HTML file..."
		if Glyph.lite? then
			out = Pathname.new Glyph['document.output_dir']
		else
			out = Glyph::PROJECT/"output/html"
		end
		extension = Glyph['document.output_ext']
		extension ||= '.html'
		out.mkpath
		file = "#{Glyph['document.filename']}#{extension}"
		file_write out/file, Glyph.document.output
		Glyph.info "'#{Glyph['document.filename']}#{extension}' generated successfully."
		unless Glyph.lite? then
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
	end

	desc "Create a pdf file"
	task :pdf => :html do
		Glyph.info "Generating PDF file..."
		if Glyph.lite? then
			out = Pathname.new Glyph['document.output_dir']
		else
			out = Glyph::PROJECT/"output/pdf"
		end
		out.mkpath
		file = Glyph['document.filename']
		case Glyph['tools.pdf_generator']
		when 'prince' then
			ENV['PATH'] += ";#{ENV['ProgramFiles']}\\Prince\\Engine\\bin" if RUBY_PLATFORM.match /mswin/ 
				res = system "prince #{Glyph::PROJECT/"output/html/#{file}.html"} -o #{out/"#{file}.pdf"}"
			if res then
				Glyph.info "'#{file}.pdf' generated successfully."
			else
				Glyph.error "An error occurred while generating #{file}.pdf"
			end
			# TODO: support other PDF renderers
		else
			Glyph.error "Glyph cannot generate PDF. Please specify a valid tools.pdf_generator setting."
		end
	end

end
