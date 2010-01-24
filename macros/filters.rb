#!/usr/bin/env ruby

macro :textile do |node|
	rc = nil
	begin
		require 'RedCloth'
		rc = RedCloth.new node[:value], Glyph::CONFIG.get("filters.redcloth.restrictions")
	rescue Exception => e
		raise #MacroError.new(node, "RedCloth gem not installed. Please run: gem insall RedCloth")
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
