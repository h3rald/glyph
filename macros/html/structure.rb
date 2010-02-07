#!/usr/bin/env ruby

macro :section do |node| 
	%{
		<div class="#{node[:macro]}">
		#{node[:value]}
		</div>
	}	
end

macro :header do |node|
	title = node.params[0]
	level = cfg("structure.first_header_level") - 1
	node.ascend do |n| 
		if cfg("structure.headers").include? n[:macro] then
			level+=1
		end
	end
	h_id = node.params[1]
	h_id ||= "h_#{node.document.headers.length+1}".to_sym
	node.document.header :title => title, :level => level, :id => h_id
	node[:id] = h_id
	node[:header] = title
	raise MacroError.new(node, "Bookmark '#{h_id}' already exists") if node.document.bookmark? h_id
	node.document.bookmark :id => h_id, :title => title
	%{
		<h#{level} id="#{h_id}">#{title}</h#{level}>
	}	
end

macro :document do |node|
	%{
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
		#{node[:value]}
</html>
	}
end

macro :body do |node|
	%{
		<body>
		#{node[:value]}
		</body>
	}
end

macro :head do |node|
	%{
		<head>
			<title>#{Glyph::CONFIG.get("document.title")}</title>
			<meta name="author" content="#{Glyph::CONFIG.get("document.author")}">
			<meta name="copyright" content="#{Glyph::CONFIG.get("document.author")}">
		#{node[:value]}
		</head>
	}
end

macro :style do |node|
	file = Glyph::PROJECT/"styles/#{node[:value]}"
	raise MacroError.new(node, "Stylesheet '#{node[:value]}' not found") unless file.exist?
	node[:style] = ""
	case file.extname
	when ".css"
		node[:style] = file_load file
	when ".sass"
		begin
			require 'sass'
			node[:style] = Sass::Engine.new(file_load(file)).render
		rescue LoadError
			raise MacroError.new node, "Haml is not installed. Please run: gem install haml"
		rescue Exception
			raise
		end
	else
		raise MacroError.new node, "Extension '#{file.extname}'"
	end
	%{
		<style>
		#{node[:style]}
		</style>
	}
end

macro :toc do |node|
	link_header = lambda do |v|
		%{<a href="##{v[:id]}">#{v[:header]}</a>}
	end
	toc = node.document.placeholder do |document|
		descend_section = lambda do |n1, added_headers|
			list = ""
			added_headers ||= []
			n1.descend do |n2, level|
				if cfg("structure.headers").include?(n2[:macro])
					header_node = n2.children.select{|n| n[:header]}[0] rescue nil
					next if added_headers.include? header_node
					added_headers << header_node
					list << "<li class=\"toc-#{n2[:macro]}\">#{link_header.call(header_node)}</li>\n" if header_node
					child_list = ""
					n2.children.each do |c|
						child_list << descend_section.call(c, added_headers)
					end	
					list << "<ul>#{child_list}</ul>\n" unless child_list.blank?
				end
			end
			list
		end
		l = cfg("structure.first_header_level")
		%{
<div class="contents">
<h#{l} id="h_toc">Table of Contents</h#{l}>
<ul class="toc">
	#{descend_section.call(document.structure, nil)}
</ul>
</div>}
	end
	toc
end

macro :index do |node|
	# TODO
	""
end

macro :bibliography do |node|
	# TODO
	""
end

# See http://microformats.org/wiki/book-brainstorming
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
