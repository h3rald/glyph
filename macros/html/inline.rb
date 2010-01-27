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

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
macro_alias '#' => :anchor
