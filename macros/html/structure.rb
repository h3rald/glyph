#!/usr/bin/env ruby

macro :section do 
	%{<div class="#{@name}">

#{@value}

		</div>}	
end

macro :header do
	title = @params[0]
	level = cfg("structure.first_header_level") - 1
	@node.ascend do |n| 
		if cfg("structure.headers").include? n[:macro] then
			level+=1
		end
	end
	h_id = @params[1]
	h_id ||= "h_#{@node[:document].headers.length+1}".to_sym
	header :title => title, :level => level, :id => h_id
	@node[:header] = h_id
	macro_error "Bookmark '#{h_id}' already exists" if bookmark? h_id
	bookmark :id => h_id, :title => title
	%{
		<h#{level} id="#{h_id}">#{title}</h#{level}>
	}	
end

macro :document do
	%{<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
		#{@value}
</html>}
end

macro :body do
	%{
		<body>
		#{@value}
		</body>
	}
end

macro :head do
	%{
		<head>
			<title>#{Glyph::CONFIG.get("document.title")}</title>
			<meta name="author" content="#{cfg("document.author")}" />
			<meta name="copyright" content="#{cfg("document.author")}" />
		#{@value}
		</head>
	}
end

macro :style do 
	file = Glyph::PROJECT/"styles/#{@value}"
	macro_error "Stylesheet '#{@value}' not found" unless file.exist?
	style = ""
	case file.extname
	when ".css"
		style = file_load file
	when ".sass"
		begin
			require 'sass'
			style = Sass::Engine.new(file_load(file)).render
		rescue LoadError
			macro_erro "Haml is not installed. Please run: gem install haml"
		rescue Exception
			raise
		end
	else
		macro_error "Extension '#{file.extname}' not supported."
	end
	%{
		<style type="text/css">
		#{style}
		</style>
	}
end

macro :toc do 
	link_header = lambda do |header|
		%{<a href="##{header[:id]}">#{header[:title]}</a>}
	end
	toc = placeholder do |document|
		descend_section = lambda do |n1, added_headers|
			list = ""
			added_headers ||= []
			n1.descend do |n2, level|
				if cfg("structure.headers").include?(n2[:macro])
					header_id = n2.children.select{|n| n[:header]}[0][:header] rescue nil
					next if added_headers.include? header_id
					added_headers << header_id
					list << "<li class=\"toc-#{n2[:macro]}\">#{link_header.call(document.header?(header_id))}</li>\n" if header_id
					child_list = ""
					n2.children.each do |c|
						child_list << descend_section.call(c, added_headers)
					end	
					list << "<li><ol>#{child_list}</ol></li>\n" unless child_list.blank?
				end
			end
			list
		end
		l = cfg("structure.first_header_level")
		%{
<div class="contents">
<h#{l} class="toc-header" id="h_toc">Table of Contents</h#{l}>
<ol class="toc">
	#{descend_section.call(document.structure, nil)}
</ol>
</div>}
	end
	toc
end

macro :index do
	# TODO
	""
end

macro :bibliography do
	# TODO
	""
end

# See http://microformats.org/wiki/book-brainstorming

macro_alias :div => :section

macro_alias :frontmatter => :div
macro_alias :bodymatter => :div
macro_alias :backmatter => :div

macro_alias :chapter => :section
macro_alias :part => :section
macro_alias :preface => :section
macro_alias :frontcover => :section
macro_alias :halftitlepage => :section
macro_alias :titlepage => :section
macro_alias :imprint => :section
macro_alias :dedication => :section
macro_alias :inspiration => :section
macro_alias :foreword => :section
macro_alias :preface => :section
macro_alias :introduction => :section
macro_alias :afterword => :section
macro_alias :appendix => :section
macro_alias :glossary => :section
macro_alias :colophon => :section
macro_alias :promotion => :section
macro_alias :backcover => :section
macro_alias :contents => :section
macro_alias :index => :section

macro_alias :heading => :header
