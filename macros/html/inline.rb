#!/usr/bin/env ruby

macro :anchor do |node|
	params = node.get_params
	node.store_id
	%{<a id="#{params[0]}">#{params[1]}</a>}
end

macro :note do |node|
	%{
		<div class="#{node[:macro]}">
			<span class="note-title">#{node[:macro].capitalize}</span>
			<span class="note-body">#{node[:value]}</span>
		</div>
	}
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

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
macro_alias '#' => :anchor
macro_alias '=>' => :link
