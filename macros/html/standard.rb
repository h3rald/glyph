#!/usr/bin/env ruby

macro :note do |value, context|
	%{
		<div class="note">
			<span class="note-title">Note</span>
			<span class="note-body">#{value}</span>
		</div>
	}
end

macro :important do |value, context|
	%{
		<div class="note important">
			<span class="note-title">Important</span>
			<span class="note-body">#{value}</span>
		</div>
	}
end

macro :tip do |value, context|
	%{
		<div class="note tip">
			<span class="note-title">Tip</span>
			<span class="note-body">#{value}</span>
		</div>
	}
end

macro :comment do |value, context|
	%{<!-- #{value} -->}
end

macro :anchor do |value, context|
	params = get_params_from value
	store_id params, context
	%{<a id="#{params[0]}">#{params[1]}</a>}
end

macro :snippet do |value, context|
	params = get_params_from value
	process get_snippet(params, context), :source => "snippet:#{params[0]}"
end

macro :escape do |value, context|
	value
end

macro_alias '--', :comment
macro_alias '#', :anchor
macro_alias '&', :snippet
macro_alias '@', :escape
