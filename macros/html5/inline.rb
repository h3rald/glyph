#!/usr/bin/env ruby

macro :fmi do
	exact_parameters 2, :level => :warning
	fmi_element_for param(0), param(1) do |topic, link|
		%{<span class="fmi">for more information on <mark>#{topic}</mark>, see #{link}</span>}
	end
end

macro :draftcomment do
	draftcomment_element do |value|
		%{<aside class="comment"><span class="comment-pre"><strong>Comment:</strong> </span>#{value}</aside>}
	end
end

macro :todo do
	exact_parameters 1
	todo_element do |value|
		%{<aside class="todo"><span class="todo-pre"><strong>TODO:</strong> </span>#{value}</aside>} 
	end
end

macro :navigation do
	exact_parameters 1
	procs = {}
	procs[:contents] = lambda do
		%{<a href="#{Glyph['document.base']}index.html">Contents</a>}
	end
	procs[:previous] = lambda do |topic|
		if topic then
			%{<a href="#{Glyph['document.base']}#{topic[:src].gsub(/\..+$/, '.html')}">#{topic[:title]} &larr;</a>}
		else
			""
		end
	end
	procs[:next] = lambda do |topic|
		if topic then
			%{<a href="#{Glyph['document.base']}#{topic[:src].gsub(/\..+$/, '.html')}">&rarr; #{topic[:title]}</a>}
		else
			""
		end
	end
	procs[:navigation] = lambda do |contents, prev_link, next_link|
		%{<nav>#{prev_link}#{contents}#{next_link}</nav>}
	end
	navigation_element_for param(0).to_sym, procs
end

macro_alias '!' => :todo
macro_alias :dc => :draftcomment
