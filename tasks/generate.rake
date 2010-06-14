#!/usr/bin/env ruby

namespace :generate do

	desc "Process source"
	task :document => ["load:all"] do
		if Glyph.lite? then
			text = file_load Pathname.new(Glyph['document.source'])
		else
			text = file_load Glyph::PROJECT/Glyph['document.source']
		end
		interpreter = Glyph::Interpreter.new text, :source => {:name => "#{Glyph['document.source']}"}, :info => true
		interpreter.parse
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
			file = (Glyph['document.output'] == 'pdf') ? Glyph['document.filename']+".html" : Glyph['document.output_file']
		else
			out = Glyph::PROJECT/"output/html"
			file = "#{Glyph['document.filename']}.html"
		end
		extension = '.html'
		out.mkpath
		file_write out/file, Glyph.document.output
		Glyph.info "'#{file}' generated successfully."
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
			src = out/"#{Glyph['document.filename']}.html"
			file = Glyph['document.output_file']
		else
			out = Glyph::PROJECT/"output/pdf"
			src = Glyph::PROJECT/"output/html/#{Glyph['document.filename']}.html"
			file = "#{Glyph['document.filename']}.pdf"
		end
		out.mkpath
		generate_pdf = lambda do |path, cmd|
			ENV['PATH'] += path if RUBY_PLATFORM.match /mswin/ 
				res = system cmd 
			if res then
				Glyph.info "'#{file}' generated successfully."
			else
				Glyph.error "An error occurred while generating #{file}"
			end
		end
		case Glyph['tools.pdf_generator']
		when 'prince' then
			generate_pdf.call ";#{ENV['ProgramFiles']}\\Prince\\Engine\\bin", %{prince #{src} -o #{out/"#{file}"}}
		when 'wkhtmltopdf' then
			generate_pdf.call ";#{ENV['ProgramFiles']}\\wkhtmltopdf", %{wkhtmltopdf #{src} #{out/"#{file}"}}
		else
			# TODO: support other PDF renderers
			Glyph.error "Glyph cannot generate PDF. Please specify a valid tools.pdf_generator setting."
		end
	end

end
