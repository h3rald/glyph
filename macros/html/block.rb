#!/usr/bin/env ruby

macro :note do
	xml_note
end

macro :box do
	exact_parameters 2
	xml_box
end

macro :codeblock do
	exact_parameters 1 
	xml_codeblock
end

macro :image do
	min_parameters 1
	max_parameters 3
	image = param(0)
	alt = "@alt[-]" unless attr(:alt)
	xml_image_for image, alt
end

macro :figure do
	min_parameters 1
	max_parameters 2
	image = param(0)
	alt = "@alt[-]" unless attr(:alt)
	caption = param(1) rescue nil
	xml_figure_for image, alt, caption
end

macro :title do
	no_parameters
	xml_title
end

macro :subtitle do
	no_parameters
	xml_subtitle
end

macro :author do
	no_parameters
	xml_author
end

macro :pubdate do
	no_parameters
	xml_pubdate
end

macro :revision do
	no_parameters
	xml_revision
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
