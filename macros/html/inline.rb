#!/usr/bin/env ruby

macro :anchor do 
	min_parameters 1
	max_parameters 2
	ident = param(0)
	title = param(1) rescue nil
	xml_bookmark_for ident, title
end

macro :link do
	min_parameters 1
	max_parameters 2
	target = param(0)
	title = param(1) rescue nil
	xml_link_for target, title
end

macro :fmi do
	exact_parameters 2, :level => :warning
	topic = param(0) 
	href = param(1)
	xml_fmi_for topic, href
end

macro :draftcomment do
	xml_draftcomment
end

macro :todo do
	exact_parameters 1
	xml_todo
end

macro_alias :bookmark => :anchor
macro_alias '#' => :anchor
macro_alias '=>' => :link
macro_alias '!' => :todo
macro_alias :dc => :draftcomment
