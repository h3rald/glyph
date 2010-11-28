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
			output = (Glyph['document.output'] == 'pdf') ? 'html' : Glyph['document.output']
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
			file = (Glyph['document.output'].in? ['pdf', 'mobi', 'epub']) ? Glyph['document.filename']+".html" : Glyph['document.output_file']
		else
			out = (Glyph['document.output'].in? ['pdf', 'mobi', 'epub']) ? 'html' : Glyph['document.output']
			out = Glyph::PROJECT/"output/#{out}"
			extension = (Glyph['document.output'].in? ['pdf', 'mobi', 'epub']) ? Glyph["output.html.extension"] : Glyph["output.#{Glyph['document.output']}.extension"]
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
		gen_calibre = lambda do |path, cmd|
			ENV['PATH'] += path if RUBY_PLATFORM.match /mswin/
			IO.popen(cmd+" 2>&1") do |pipe|
				pipe.sync = true
				while str = pipe.gets do
					puts str
				end
			end
		end
		cover_opt = ""
    ebook_isbn = Glyph['document.isbn'] || Glyph['document.title'].hash
    cover_art = Glyph['document.cover'] 
    output_profile = Glyph["#{output_cfg}.profile"]
		cover_opt = "--cover \"#{Glyph::PROJECT}/images/#{cover_art}\"" unless cover_art.blank?
    html_file = "#{Glyph::PROJECT}/output/html/#{Glyph['document.filename']}.html"
    out_dir = "#{Glyph::PROJECT}/output/#{out}"
    Pathname.new(out_dir).mkpath
    calibre_cmd = "ebook-convert #{html_file} #{out_dir}/#{Glyph['document.filename']}.#{out} --title \"#{Glyph['document.filename']}\" --authors \"\" --isbn \"#{ebook_isbn}\" #{cover_opt} --output-profile #{output_profile}"
		windows_path = ""
    gen_calibre.call windows_path, calibre_cmd
	  Glyph.info "Done."
	end

	desc "Create an e-book file in .mobi (Kindle) format"
	task :mobi => [:calibre] do; end

	desc "Create an e-book file in .epub (Nook/Kobo/etc.) format"
	task :epub => [:calibre] do; end

  desc "Generate .mobi and .epub ebook files"
  task :ebooks => [:mobi, :epub] do ; end

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

	desc "Create a pdf file"
	task :pdf => :html do
		info "Generating PDF file..."
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
			IO.popen(cmd+" 2>&1") do |pipe|
				pipe.sync = true
				while str = pipe.gets do
					puts str
				end
			end
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

end
