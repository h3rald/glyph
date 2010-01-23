#!/usr/bin/env ruby

macro :note do |node|
	%{
		<div class="note">
			<span class="note-title">Note</span>
			<span class="note-body">#{node[:value]}</span>
		</div>
	}
end

macro :important do |node|
	%{
		<div class="note important">
			<span class="note-title">Important</span>
			<span class="note-body">#{node[:value]}</span>
		</div>
	}
end

macro :tip do |node|
	%{
		<div class="note tip">
			<span class="note-title">Tip</span>
			<span class="note-body">#{node[:value]}</span>
		</div>
	}
end

macro :comment do |node|
	%{<!-- #{node[:value]} -->}
end

macro :anchor do |node|
	params = get_params_from node[:value]
	store_id params, node
	%{<a id="#{params[0]}">#{params[1]}</a>}
end

macro :snippet do |node|
	params = get_params_from node[:value]
	process get_snippet(params, node), :source => "snippet: #{params[0]}"
end

macro :escape do |node|
	node[:value]
end

macro_alias '--', :comment
macro_alias '#', :anchor
macro_alias '&', :snippet
macro_alias '@', :escape
