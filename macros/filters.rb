#!/usr/bin/env ruby

macro :textile do
	exact_parameters 1
	begin
		require 'RedCloth'
	rescue Exception
		macro_error "RedCloth gem not installed. Please run: gem install RedCloth"
	end
	rc = RedCloth.new value, Glyph::CONFIG.get("filters.redcloth.restrictions")
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
	begin
		raise LoadError unless markdown_converter
		require markdown_converter.to_s
	rescue LoadError
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
						macro_error "No supported MarkDown converter installed. Please run: gem install bluecloth"
					end
				end
			end
		end
	end
	Glyph["filters.markdown_converter"] = markdown_converter
	case markdown_converter
	when :bluecloth
		md = BlueCloth.new value
	when :rdiscount
		md = RDiscount.new value
	when :maruku
		md = Maruku.new value
	when :kramdown
		md = Kramdown::Document.new value
	else
	 macro_error "No supported MarkDown converter installed. Please run: gem install bluecloth"
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
	lang = param(0)
	text = param(1)
	text.gsub!(/\\(.)/){$1}
	highlighter = Glyph["filters.highlighter"].to_sym rescue nil
	begin
		raise LoadError unless highlighter
		if highlighter.to_s.match(/^(uv|ultraviolet)$/) then
			require 'uv'
		else
			require highlighter.to_s
		end
	rescue LoadError
		begin
			require 'coderay'
			highlighter = :coderay
		rescue LoadError
			begin 
				require 'uv'
				highlighter = :ultraviolet
			rescue LoadError
				macro_error "No supported highlighter installed. Please run: gem install coderay"
			end
		end
	end
	Glyph["highlighter.current"] = highlighter
	target = Glyph["filters.target"]
	result = ""
	case highlighter.to_sym
	when :coderay
		begin
			result = CodeRay.scan(text, lang).div(Glyph["filters.coderay"])
		rescue Exception => e
			macro_error e.message
		end
	when :ultraviolet
		begin
			target = 'xhtml' if target.to_s == 'html'
			result = Uv.parse(text.to_s, target.to_s, lang.to_s, 
							 Glyph["filters.ultraviolet.line_numbers"], 
							 Glyph["filters.ultraviolet.theme"].to_s)
		rescue Exception => e
			macro_error e.message
		end
	else
		macro_error "No supported highlighter installed. Please run: gem install coderay"
	end
	result
end

macro_alias :md => :markdown
macro_alias :txt => :textile
