#!/usr/bin/env ruby

namespace :generate do

	def with_files_from(dir, &block)
		output = Glyph['document.output']
		dir_path = Glyph::PROJECT/"output/#{output}/#{dir}"
		dir_path.mkpath
		# Copy images
		(Glyph::PROJECT/dir).find do |i|
			if i.file? then
				dest = "#{Glyph::PROJECT/"output/#{output}/#{dir}"}/#{i.relative_path_from(Glyph::PROJECT/dir)}"
				src = i.to_s
				Pathname.new(dest).parent.mkpath
				block.call src, dest
			end
		end
	end

	desc "Copy image files"
	task :images => [:document] do
		unless Glyph.lite? then
			Glyph.info "Copying images..."
			with_files_from('images') do |src, dest|
				file_copy src, dest
			end
		end
	end

	desc "Copy style files"
	task :styles => [:document] do
		if Glyph['document.styles'].in?(['link', 'import']) && !Glyph.lite? then
			Glyph.info "Copying stylesheets..."
			out_dir = Glyph::PROJECT/"output/#{Glyph['document.output']}/styles"
			out_dir.mkdir
			Glyph.document.styles.each do |f|
				case
				when f.extname == ".css" then
					file_copy f, out_dir/f.basename 
				when f.extname == ".sass" then
					style = Sass::Engine.new(file_load(f.to_s)).render
					out_file = out_dir/f.basename.to_s.gsub(/\.sass$/, '.css')
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
		name = Glyph['document.source']
		interpreter = Glyph::Interpreter.new text, :source => {:name => name, :file => name}, :info => true
		interpreter.parse
		Glyph.info "Processing..."
		interpreter.process
		Glyph.info "Post-processing..."
		interpreter.postprocess
		Glyph.document = interpreter.document
	end

	desc "Create a standalone html file"
	task :html => [:document, :images, :styles] do
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
	end

	desc "Create multiple HTML files"
	task :web => [:document, :images, :styles] do
		Glyph.info "Generating HTML files..."
		if Glyph.lite? then
			out = Pathname.new Glyph['document.output_dir']
		else
			out = Glyph::PROJECT/"output/web"
		end
		raise RuntimeError, "You cannot have an 'images' directory under your 'text' directory." if (Glyph::PROJECT/"text/images").exist?
		raise RuntimeError, "You cannot have a 'styles' directory under your 'text' directory." if (Glyph::PROJECT/"text/styles").exist?
		out.mkpath
		file_write out/"index.html", Glyph.document.output
		Glyph.document.structure.descend do |node, level|
			if node.is_a?(Glyph::MacroNode) && Glyph.macro_eq?(node[:name], :include) then
				doc = Glyph::Document.new node.children.last, {:source => node.children.last[:source]}
				doc.inherit_from Glyph.document
				out_file = Pathname.new((out/doc.context[:source][:file]).to_s.gsub(/\..+$/, '.html').gsub(/text\//, ''))
				out_file.parent.mkpath
				# TODO: Refactor this: currently the document is evaluated twice:
				# - for the whole thing
				# - for each file
				doc.analyze
				doc.finalize
				file_write out_file, doc.output
			end
		end
		Glyph.info "'#{file}' generated successfully."
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
			IO.popen(cmd+" 2>&1") do |pipe|
				pipe.sync = true
				while str = pipe.gets do
					puts str
				end
			end	
			if (out/file).exist? then
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
