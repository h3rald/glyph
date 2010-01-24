#!/usr/bin/env ruby

macro :textile do |node|
	rc = nil
	begin
		require 'RedCloth'
		rc = RedCloth.new node[:value], Glyph::CONFIG.get("filters.redcloth.restrictions")
	rescue Exception => e
		raise MacroError.new(node, "RedCloth gem not installed. Please run: gem insall RedCloth")
	end
	target = Glyph::CONFIG.get("filters.target")
	case target.to_sym
	when :html
		rc.to_html
	when :latex
		rc.to_latex
	else
		raise MacroError.new(node, "RedCloth does not support target '#{target}'")
	end
end

macro :markdown do |node|
	md = nil
	markdown_converter = Glyph::CONFIG.get "filters.markdown_converter"
	if !markdown_converter then
		begin
			require 'bluecloth'
			markdown_converter = :BlueCloth
		rescue LoadError
			begin 
				require 'rdiscount'
				markdown_converter = :RDiscount
			rescue LoadError
				begin 
					require 'maruku'
					markdown_converter = :Maruku
				rescue LoadError
					begin 
						require 'kramdown'
						markdown_converter = :Kramdown
					rescue LoadError
						raise MacroError.new(node, "No MarkDown converter installed. Please run: gem insall bluecloth")
					end
				end
			end
		end
		Glyph.config_override "filters.markdown_converter", markdown_converter
	end
	case markdown_converter
	when :BlueCloth
		md = BlueCloth.new node[:value]
	when :RDiscount
		md = RDiscount.new node[:value]
	when :Maruku
		md = Maruku.new node[:value]
	when :Kramdown
		md = Kramdown::Document.new node[:value]
	else
		raise MacroError.new(node, "No MarkDown converter installed. Please run: gem insall bluecloth")
	end
	target = Glyph::CONFIG.get("filters.target")
	if target.to_sym == :html then
		md.to_html
	else
		raise MacroError.new(node, "#{markdown_converter} does not support target '#{target}'")
	end
end

macro_alias :md, :markdown
