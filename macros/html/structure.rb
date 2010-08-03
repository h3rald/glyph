#!/usr/bin/env ruby

macro :section do 
	max_parameters 1
	if raw_attribute(:src) && Glyph.multiple_output_files? then
		within :contents
		required_attribute :title
	end
	procs = {}
	procs[:title] = lambda do |level, ident, title|
		%{<h#{level} id="#{ident}">#{title}</h#{level}>\n}	
	end
	procs[:body] = lambda do |title, value|
		%{<div class="#{@name}">
#{title}#{value}

</div>}	
	end
	section_element_for procs
end

macro :article do
	exact_parameters 1
	head = raw_attr(:head)
 	head ||= %{style[default.css]}
	pre_title = raw_attr(:"pre-title")
	post_title = raw_attr(:"post-title")
	pubdate = @node.attr(:pubdate) ? "div[@class[pubdate]#{@node.attr(:pubdate).contents}]" : "pubdate[]"
	halftitlepage = raw_attr(:halftitlepage)
	halftitlepage ||= %{
			#{pre_title}
			title[]
			subtitle[]
			author[]
			#{pubdate}
			#{post_title}
	}
	interpret %{document[
	head[#{head}]
	body[
		halftitlepage[
			#{halftitlepage}
		]
		#{@node.value}
	]
]}	
end

macro :book do
	no_parameters
	head = raw_attr(:head) 
	head ||= %{style[default.css]}
	pre_title = raw_attr(:"pre-title")
	post_title = raw_attr(:"post-title")
	titlepage = raw_attr(:titlepage)
	pubdate = @node.attr(:pubdate) ? "div[@class[pubdate]#{@node.attr(:pubdate).contents}]" : "pubdate[]"
	titlepage ||= %{
			#{pre_title}
			title[]
			subtitle[]
			revision[]
			author[]
			#{pubdate}
			#{post_title}
	}
	frontmatter = raw_attr(:frontmatter)
	bodymatter = raw_attr(:bodymatter)
	backmatter = raw_attr(:backmatter)
	frontmatter = "frontmatter[\n#{frontmatter}\n]" if frontmatter
	bodymatter = "bodymatter[\n#{bodymatter}\n]" if bodymatter
	backmatter = "backmatter[\n#{backmatter}\n]" if backmatter
	interpret %{document[
	head[#{head}]
	body[
		titlepage[
			#{titlepage}
		]
		#{frontmatter}
		#{bodymatter}
		#{backmatter}
	]
]}	
end


macro :document do
	exact_parameters 1
	%{<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
#{value}

</html>}
end

macro :head do
	exact_parameters 1
	author = Glyph['document.author'].blank? ? "" : %{<meta name="author" content="#{Glyph["document.author"]}" />
}
	copy = Glyph['document.author'].blank? ? "" : %{<meta name="copyright" content="#{Glyph["document.author"]}" />}
	%{<head>
<title>#{Glyph["document.title"]}</title>
#{author}
#{copy}
<meta name="generator" content="Glyph v#{Glyph::VERSION} (http://www.h3rald.com/glyph)" />
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
#{value}
</head>
}
end

macro :style do 
	exact_parameters 1
	file = Glyph.lite? ? Pathname.new(value) : Glyph::PROJECT/"styles/#{value}"
	file = Pathname.new Glyph::HOME/'styles'/value unless file.exist?
	macro_error "Stylesheet '#{value}' not found" unless file.exist?

	@node[:document].style file
	case Glyph['document.styles'].to_s
	when 'embed' then
		style = ""
		case file.extname
		when ".css"
			style = file_load file
		when ".sass"
			begin
				require 'sass'
				style = Sass::Engine.new(file_load(file)).render
			rescue LoadError
				macro_error "Haml is not installed. Please run: gem install haml"
			rescue Exception
				raise
			end
		else
			macro_error "Extension '#{file.extname}' not supported."
		end
%{<style type="text/css">
			#{style}
</style>}
	when 'import' then
%{<style type="text/css">
	@import url("#{Glyph["output.#{Glyph['document.output']}.base"]}styles/#{value.gsub(/\..+$/, '.css')}");
</style>}
	when 'link' then
%{<link href="#{Glyph["output.#{Glyph['document.output']}.base"]}styles/#{value.gsub(/\..+$/, '.css')}" type="text/css" />}
	else
		macro_error "Value '#{Glyph['document.styles']}' not allowed for 'document.styles' setting"
	end
end

macro :toc do 
	max_parameters 1
	link_proc = lambda do |head|
		%{<a href="#{head.link(@source_file)}">#{head.title}</a>}
	end
	toc_list_proc = lambda do |descend_proc, bmk, document|
		%{<div class="contents">
<h2 class="toc-header" id="#{bmk}">#{bmk.title}</h2>
<ol class="toc">
						#{descend_proc.call(document.structure, nil)}
</ol>
</div>}
	end
	toc_item_proc = lambda do |classes, header|
		"<li class=\"#{classes.join(" ").strip}\">#{header}</li>"
	end
	toc_sublist_proc = lambda do |contents|
		"<li><ol>#{contents}</ol></li>\n"
	end
	toc_element_for param(0), attr(:title), 
		:link => link_proc, 
		:toc_list => toc_list_proc, 
		:toc_item => toc_item_proc, 
		:toc_sublist => toc_sublist_proc
end

macro :contents do
	result = interpret(@node.parameter(0).to_s)
	Glyph.multiple_output_files? ? "" : result
end

# See:
#  http://microformats.org/wiki/book-brainstorming
#  http://en.wikipedia.org/wiki/Book_design

(Glyph['system.structure.frontmatter'] + Glyph['system.structure.bodymatter'] + Glyph['system.structure.backmatter']).
	each {|s| macro_alias s => :section }

macro_alias :frontcover => :section
macro_alias :titlepage => :section
macro_alias :halftitlepage => :section
macro_alias :frontmatter => :section
macro_alias :bodymatter => :section
macro_alias :backmatter => :section
macro_alias :backcover => :section
