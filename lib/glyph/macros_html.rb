#!/usr/bin/env ruby

macro :note do |params, meta|
	%{
		<div class="note">
			<span class="note-title">Note</span>
			<span class="note-body">#{params[0]}</span>
		</div>
	}
end

macro :important do |params, meta|
	%{
		<div class="note important">
			<span class="note-title">Important</span>
			<span class="note-body">#{params[0]}</span>
		</div>
	}
end

macro :tip do |params, meta|
	%{
		<div class="note tip">
			<span class="note-title">Tip</span>
			<span class="note-body">#{params[0]}</span>
		</div>
	}
end

macro :comment do |params, meta|
	%{<!-- #{params[0]} -->}
end

macro :anchor do |params, meta|
	store_id params, meta
	%{<a id="#{params[0]}">#{params[1]}</a>}
end

macro :snippet do |params, meta|
	get_snippet params, meta
end

macro_alias '--', :comment
macro_alias '#', :anchor
macro_alias '&', :snippet


