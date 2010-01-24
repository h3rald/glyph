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
	params = get_params_from node
	store_id_from node
	%{<a id="#{params[0]}">#{params[1]}</a>}
end

macro :snippet do |node|
	node[:source] << "snippet: #{node[:value]}"
	process get_snippet_from(node), node
end

macro :include do |node|
	node[:source] << "file: #{node[:file]}"
	process load_file_from(node), node
end

macro :section do |node| 
	%{
		<div class="section">
			#{node[:value]}
		</div>
	}	
end

macro :title do |node|
	title, level = get_title_from node
	%{
		<h#{level}>#{title}</h#{level}>
	}	
end

macro :escape do |node| 
	node[:value] 
end

macro_alias '--', :comment
macro_alias '#', :anchor
macro_alias '&', :snippet
macro_alias '%', :escape
macro_alias :chapter, :section
macro_alias :header, :title
macro_alias :heading, :title
macro_alias "===", :title
macro_alias "@", :include
