#!/usr/bin/env ruby

macro :anchor do 
	min_parameters 1
	max_parameters 2
	bookmark :id => param(0), :title => param(1), :file => @source_file
	%{<a id="#{param(0)}">#{(param(1) rescue nil)}</a>}
end

macro :link do
	min_parameters 1
	max_parameters 2
	link_element_for param(0), (param(1) rescue nil) do |target, title|
		%{<a href="#{target}">#{title}</a>}
	end
end

macro :fmi do
	exact_parameters 2, :level => :warning
	fmi_element_for param(0), param(1) do |topic, link|
		%{<span class="fmi">for more information on #{topic}, see #{link}</span>}
	end
end

macro :draftcomment do
	draftcomment_element do |value|
		%{<span class="comment"><span class="comment-pre"><strong>Comment:</strong> </span>#{value}</span>}
	end
end

macro :todo do
	exact_parameters 1
	todo_element do |value|
		%{<span class="todo"><span class="todo-pre"><strong>TODO:</strong> </span>#{value}</span>} 
	end
end

macro :navigation do
	exact_parameters 1
	procs = {}
	procs[:contents] = lambda do
		%{<a href="#{Glyph["output.#{Glyph['document.output']}.base"]}index.html">Contents</a>}
	end
	procs[:previous] = lambda do |topic|
		if topic then
			%{<a href="#{Glyph["output.#{Glyph['document.output']}.base"]}#{topic[:src].gsub(/\..+$/, '.html')}">#{topic[:title]} &larr;</a>}
		else
			""
		end
	end
	procs[:next] = lambda do |topic|
		if topic then
			%{<a href="#{Glyph["output.#{Glyph['document.output']}.base"]}#{topic[:src].gsub(/\..+$/, '.html')}">&rarr; #{topic[:title]}</a>}
		else
			""
		end
	end
	procs[:navigation] = lambda do |contents, prev_link, next_link|
		%{<div class="navigation">#{prev_link}#{contents}#{next_link}</div>}
	end
	navigation_element_for param(0).to_sym, procs
end

macro_alias :bookmark => :anchor
macro_alias '#' => :anchor
macro_alias '=>' => :link
macro_alias '!' => :todo
macro_alias :dc => :draftcomment
