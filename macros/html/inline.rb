#!/usr/bin/env ruby

macro :anchor do |node|
	ident, title = node.params
	raise MacroError.new(node, "Bookmark '#{ident}' already exists") if node.document.bookmark? ident
	node.document.bookmark :id => ident, :title => title
	%{<a id="#{ident}">#{title}</a>}
end

macro :link do |node|
	href, title = node.params
	if href.match /^#/ then
		anchor = href.gsub(/^#/, '').to_sym
		title = node.document.placeholder do |document|
			# TODO: warn if it doesn't exist
			document.bookmarks[anchor][:title]
		end
	end
	title ||= href
	%{<a href="#{href}">#{title}</a>}
end

macro :fmi do |node|
	# TODO
	topic, href = node.params
	context = {:source => "macro: fmi", :document => node.document}
	res = Glyph::Interpreter.new("=>[#{link}]", context).document	
	%{<span class="fmi">For more information on #{topic}, see #{res}</span>}
end

macro :term do |node|
	# TODO
	""
end

macro :biblio do |node|
	# TODO
	""
end

macro :fn do |node|
	# TODO
	""
end

macro_alias :bookmark => :anchor
macro_alias '#' => :anchor
macro_alias '=>' => :link
macro_alias '+' => :term
