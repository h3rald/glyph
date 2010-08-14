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

macro_alias '!' => :todo
macro_alias :dc => :draftcomment
