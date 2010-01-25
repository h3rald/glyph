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
	node[:source] = "snippet: #{node[:value]}"
	process(get_snippet_from(node), node)[:output]
end

macro :include do |node|
	contents = load_file_from(node)
	if Glyph::CONFIG.get "filters.by_file_extension" then
		ext = node[:value].match(/\.(.*)$/)[1]
		raise MacroError.new(node, "Macro '#{ext}' not found") unless Glyph::MACROS.include?(ext.to_sym)
		contents = "#{ext}[#{contents}]"
	end	
	node[:source] = "file: #{node[:value]}"
	process(contents, node)[:output]
end

macro :section do |node| 
	%{
		<div class="section">
			#{node[:value]}
		</div>
	}	
end

macro :title do |node|
	title_node = get_title_from node
	%{
		<h#{title_node[:level]} id="#{title_node[:id]}">#{title_node[:title]}</h#{title_node[:level]}>
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
macro_alias "@", :include
