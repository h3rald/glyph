#!/usr/bin/env ruby

macro :anchor do |node|
	params = node.get_params
	node.store_id
	%{<a id="#{params[0]}">#{params[1]}</a>}
end

macro :link do |node|
	params = node.get_params
	anchor = params[0].gsub(/^#/, '').to_sym
	if Glyph::IDS.has_key? anchor then
		params[1] ||= Glyph::IDS[anchor]
	end
	params[1] ||= params[0]
	%{<a href="#{params[0]}">#{params[1]}</a>}
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

macro_alias '#' => :anchor
macro_alias '=>' => :link
macro_alias '+' => :term
