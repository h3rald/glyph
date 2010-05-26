#!/usr/bin/env ruby

macro :section do 
	exact_parameters 1, :level => :warning
%{<div class="#{@name}">
#{value.strip}

</div>}	
end

macro :header do
	min_parameters 1
	max_parameters 2
	title = param(0)
	h_id = param(1)
	h_id = nil if h_id.blank?
	level = 1
	@node.ascend do |n| 
		if n[:type] == :macro && Glyph["system.structure.headers"].include?(n[:name]) then
			level+=1
		end
	end
	h_id ||= "h_#{@node[:document].headers.length+1}".to_sym
	header :title => title, :level => level, :id => h_id
	@node[:header] = h_id
	macro_error "Bookmark '#{h_id}' already exists" if bookmark? h_id
	bookmark :id => h_id, :title => title
	%{<h#{level} id="#{h_id}">#{title}</h#{level}>}	
end

macro :document do
	exact_parameters 1, :level => :warning
	%{<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
#{value}

</html>}
end

macro :body do
	exact_parameters 1, :level => :warning
	%{<body>
#{value}

</body>}
end

macro :head do
	exact_parameters 1, :level => :warning
	%{<head>
<title>#{Glyph["document.title"]}</title>
<meta name="author" content="#{Glyph["document.author"]}" />
<meta name="copyright" content="#{Glyph["document.author"]}" />
<meta name="generator" content="Glyph v#{Glyph::VERSION} (http://www.h3rald.com/glyph)" />
#{value}
</head>
}
end

macro :style do 
	file = Glyph.lite? ? Pathname.new(value) : Glyph::PROJECT/"styles/#{value.strip}"
	file = Pathname.new Glyph::HOME/'styles'/value.strip unless file.exist?
	macro_error "Stylesheet '#{value.strip}' not found" unless file.exist?
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
end

macro :toc do 
	no_parameters
	link_header = lambda do |header|
		%{<a href="##{header[:id]}">#{header[:title].gsub(/@(.+?)@/, '\1')}</a>}
	end
	toc = placeholder do |document|
		descend_section = lambda do |n1, added_headers|
			list = ""
			added_headers ||= []
			n1.descend do |n2, level|
				if Glyph['system.structure.headers'].include?(n2[:macro])
					next if n2.find_parent{|node| Glyph['system.structure.special'].include? node[:macro] } 
					header_id = n2.children.select{|n| n[:header]}[0][:header] rescue nil
					next if added_headers.include? header_id
					added_headers << header_id
					# Check if part of frontmatter, bodymatter or backmatter
					container = n2.find_parent{|node| node[:macro].in? [:frontmatter, :bodymatter, :appendix, :backmatter]}[:macro] rescue nil
					list << "<li class=\"#{container} #{n2[:macro]}\">#{link_header.call(document.header?(header_id))}</li>\n" if header_id
					child_list = ""
					n2.children.each do |c|
						child_list << descend_section.call(c, added_headers)
					end	
					list << "<li><ol>#{child_list}</ol></li>\n" unless child_list.blank?
				end
			end
			list
		end
		%{<div class="contents">
<h2 class="toc-header" id="h_toc">Table of Contents</h2>
<ol class="toc">
#{descend_section.call(document.structure, nil)}
</ol>
</div>}
	end
	toc
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
