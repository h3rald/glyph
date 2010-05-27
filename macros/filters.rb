#!/usr/bin/env ruby

macro :textile do
	exact_parameters 1, :level => :warning
	rc = nil
	begin
		require 'RedCloth'
		rc = RedCloth.new value.strip, Glyph::CONFIG.get("filters.redcloth.restrictions")
	rescue Exception
		macro_error "RedCloth gem not installed. Please run: gem insall RedCloth"
	end
	target = Glyph["filters.target"]
	case target.to_sym
	when :html
		rc.to_html.gsub /<p><\/p>/, ''
	when :latex
		rc.to_latex
	else
		macro_error "RedCloth does not support target '#{target}'"
	end
end

macro :markdown do
	exact_parameters 1, :level => :warning
	md = nil
	markdown_converter = Glyph["filters.markdown_converter"].to_sym rescue nil
	if !markdown_converter then
		begin
			require 'bluecloth'
			markdown_converter = :bluecloth
		rescue LoadError
			begin 
				require 'rdiscount'
				markdown_converter = :rdiscount
			rescue LoadError
				begin 
					require 'maruku'
					markdown_converter = :maruku
				rescue LoadError
					begin 
						require 'kramdown'
						markdown_converter = :kramdown
					rescue LoadError
						macro_error "No MarkDown converter installed. Please run: gem install bluecloth"
					end
				end
			end
		end
		Glyph["filters.markdown_converter"] = markdown_converter
	end
	case markdown_converter
	when :bluecloth
		require 'bluecloth'
		md = BlueCloth.new value.strip
	when :rdiscount
		require 'rdiscount'
		md = RDiscount.new value.strip
	when :maruku
		require 'maruku'
		md = Maruku.new value.strip
	when :kramdown
		require 'kramdown'
		md = Kramdown::Document.new value.strip
	else
	 macro_error "No MarkDown converter installed. Please run: gem install bluecloth"
	end
	target = Glyph["filters.target"]
	if target.to_sym == :html then
		md.to_html
	else
		macro_error "#{markdown_converter} does not support target '#{target}'"
	end
end

macro :highlight do
	exact_parameters 2  
	lang = param(0).strip
	text = param(1).strip
	text.gsub!(/\\(.)/){$1}
	highlighter = Glyph["highlighters.current"].to_sym rescue nil
	if !highlighter then
		begin
			require 'coderay'
			highlighter = :coderay
		rescue LoadError
			begin 
				require 'uv'
				highlighter = :ultraviolet
			rescue LoadError
				macro_error "No highlighter installed. Please run: gem install coderay"
			end
		end
		Glyph["highlighter.current"] = highlighter
	end
	target = Glyph["highlighters.target"]
	result = ""
	case highlighter.to_sym
	when :coderay
		begin
			require 'coderay'
			result = CodeRay.scan(text, lang).div(Glyph["highlighters.coderay"])
		rescue LoadError
			macro_error "CodeRay highlighter not installed. Please run: gem install coderay"
		rescue Exception => e
			macro_error e.message
		end
	when :ultraviolet
		begin
			require 'uv'
			target = 'xhtml' if target == 'html'
			result = Uv.parse(text.to_s, target.to_s, lang.to_s, 
							 Glyph["highlighters.ultraviolet.line_numbers"], 
							 Glyph["highlighters.ultraviolet.theme"].to_s)
		rescue LoadError
			macro_error "UltraViolet highlighter not installed. Please run: gem install ultraviolet"
		rescue Exception => e
			puts e.backtrace
			macro_error e.message
		end
	else
		macro_error "No highlighter installed. Please run: gem install coderay"
	end
	result
end

macro_alias :md => :markdown
