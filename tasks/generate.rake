#!/usr/bin/env ruby

namespace :generate do

	include Glyph::Utils

	desc "Copy image files"
	task :images => [:document] do
		unless Glyph.lite? then
			info "Copying images..."
			with_files_from('images') do |src, dest|
				file_copy src, dest
			end
		end
	end

	desc "Copy style files"
	task :styles => [:document] do
		if Glyph['document.styles'].in?(['link', 'import']) && !Glyph.lite? then
			info "Copying stylesheets..."
			output = complex_output?  ? 'tmp' : Glyph['document.output']
			out_dir = Glyph::PROJECT/"output/#{output}/styles"
			Glyph.document.styles.each do |f|
				styles_dir = f.parent.to_s.include?(Glyph::HOME/'styles') ? Glyph::HOME/'styles' : Glyph::PROJECT/'styles'
				subdir = f.parent.relative_path_from(styles_dir).to_s.gsub(/^\./, '')
				dir = out_dir/subdir
				dir.mkpath
				case
				when f.extname == ".css" then
					file_copy f, dir/f.basename
				when f.extname == ".sass" then
					style = Sass::Engine.new(file_load(f.to_s)).render
					out_file = dir/f.basename.to_s.gsub(/\.sass$/, '.css')
					file_write out_file, style
				else
					raise RuntimeError, "Unsupported stylesheet: '#{f.basename}'"
				end
			end
		end
	end

	desc "Process source files and create a Glyph document"
	task :document => ["load:all"] do
		if Glyph.lite? then
			text = file_load Pathname.new(Glyph['document.source'])
		else
			text = file_load Glyph::PROJECT/Glyph['document.source']
		end
		require 'net/http' if Glyph['options.url_validation']
		name = Glyph['document.source']
		interpreter = Glyph::Interpreter.new text, :source => {:name => name, :file => name, :topic => nil}, :info => true
		interpreter.parse
		info "Processing..."
		interpreter.process
		info "Post-processing..."
		interpreter.postprocess
		Glyph.document = interpreter.document
	end

	desc "Create a standalone HTML file"
	task :html => [:images, :styles] do
		info "Generating HTML file..."
		if Glyph.lite? then
			out = Pathname.new Glyph['document.output_dir']
			file = complex_output? ? Glyph['document.filename']+".html" : Glyph['document.output_file']
		else
			out = complex_output? ? 'tmp' : Glyph['document.output']
			out = Glyph::PROJECT/"output/#{out}"
			extension = complex_output? ? Glyph["output.html.extension"] : Glyph["output.#{Glyph['document.output']}.extension"]
			file = "#{Glyph['document.filename']}#{extension}"
		end
		out.mkpath
		file_write out/file, Glyph.document.output
		info "'#{file}' generated successfully."
	end

	desc "Create a standalone HTML 5 file"
	task :html5 => [:html] do; end

	task :calibre => [:html] do
		out = Glyph['document.output']
		output_cfg = "output.#{out}"
		# TODO: support other e-book renderers
		unless Glyph["#{output_cfg}.generator"] == "calibre" then
			error "Glyph cannot generate e-book. At present, output.#{out}.generator can only be set to 'calibre'" 
		end
	  Glyph.info "Generating #{Glyph['document.output'].upcase} e-book..."
		options = Glyph[output_cfg][:calibre].dup
		options[:isbn] = Glyph['document.isbn'] unless Glyph["document.isbn"].blank?
		options[:cover] = "#{Glyph::PROJECT}/images/#{Glyph['document.cover']}" unless Glyph["document.cover"].blank?
		options[:title] = Glyph["document.title"]
		options[:authors] = Glyph["document.author"]
    html_file = "#{Glyph::PROJECT}/output/tmp/#{Glyph['document.filename']}.html"
    out_dir = "#{Glyph::PROJECT}/output/#{out}"
		out_file = "#{Glyph['document.filename']}.#{out}" 
		out_path = Pathname.new "#{out_dir}/#{out_file}"
    Pathname.new(out_dir).mkpath
    calibre_cmd = "ebook-convert #{html_file} #{out_path} #{options.to_options}"
		run_external_command calibre_cmd
		# Remove stylesheets and images (copied by default to output directory)
		(Pathname.new(out_dir)/"images").rmtree rescue nil
		(Pathname.new(out_dir)/"styles").rmtree rescue nil
		if out_path.exist? then
			info "'#{out_file}' generated successfully."
		else
			error "An error occurred while generating #{out_file}"
		end
	end

	[:mobi, :epub].each do |out|
		desc "Create an e-book file in #{out} format"
		task out => [:calibre] do; end
	end

	desc "Create multiple HTML files"
	task :web => [:images, :styles] do
		info "Generating HTML files..."
		if Glyph.lite? then
			out = Pathname.new Glyph['document.output_dir']
		else
			out = Glyph::PROJECT/"output/#{Glyph['document.output']}"
		end
		raise RuntimeError, "You cannot have an 'images' directory under your 'text' directory." if (Glyph::PROJECT/"text/images").exist?
		raise RuntimeError, "You cannot have a 'styles' directory under your 'text' directory." if (Glyph::PROJECT/"text/styles").exist?
		out.mkpath
		index_layout = Glyph["output.#{Glyph['document.output']}.layouts.index"] || :index
		# Generate index topic
		context = {}
		context[:document] = Glyph::Document.new(Glyph::DocumentNode.new).inherit_from(Glyph.document, :topics => false)
		context[:source] = {:name => "layout/#{index_layout}", :file => "layouts/#{index_layout}.glyph"}
		# Do not display errors (already displayed when document is finalized).
		q = Glyph['system.quiet']
		Glyph['system.quiet'] = true
		index_topic = Glyph::Interpreter.new("layout/#{index_layout}[]", context).document.output
		Glyph['system.quiet'] = q
		file_write out/"index.html", index_topic
		# Generate all topics
		Glyph.document.topics.each do |topic|
			extension = "#{Glyph["output.#{Glyph['document.output']}.extension"]}"
			file = topic[:src].gsub(/\..+$/, extension)
			file += extension unless file.match /#{Regexp.escape(extension)}$/
			info "Generating topic '#{file}'"
			(out/file).parent.mkpath
			file_write out/file, topic[:contents]
		end
		info "Web output generated successfully."
	end

	desc "Create multiple HTML 5 files"
	task :web5 => [:web] do; end

	desc "Create a pdf file (do not call directly)"
	task :pdf do
		info "Generating PDF file..."
		if Glyph.lite? then
			out = Pathname.new Glyph['document.output_dir']
			src = out/"#{Glyph['document.filename']}.html"
			file = Glyph['document.output_file']
		else
			out = Glyph::PROJECT/"output/pdf"
			src = Glyph::PROJECT/"output/tmp/#{Glyph['document.filename']}.html"
			file = "#{Glyph['document.filename']}.pdf"
		end
		out.mkpath
		generate_pdf = lambda do |path, cmd|
			ENV['PATH'] += path if RUBY_PLATFORM.match /mswin/
			run_external_command cmd
			if (out/file).exist? then
				info "'#{file}' generated successfully."
			else
				error "An error occurred while generating #{file}"
			end
		end
		case Glyph['output.pdf.generator']
		when 'prince' then
			generate_pdf.call ";#{ENV['ProgramFiles']}\\Prince\\Engine\\bin", %{prince #{src} -o #{out/"#{file}"}}
		when 'wkhtmltopdf' then
			generate_pdf.call ";#{ENV['ProgramFiles']}\\wkhtmltopdf", %{wkhtmltopdf #{src} #{out/"#{file}"}}
		else
			# TODO: support other PDF renderers
			error "Glyph cannot generate PDF. Please specify a valid output.pdf.generator setting."
		end
	end

	desc "Create a pdf file through html"
	task :pdf_through_html => [:html, :pdf] do; end

	desc "Create a pdf file through html5"
	task :pdf_through_html5 => [:html5, :pdf] do; end

end
