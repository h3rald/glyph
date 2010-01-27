#!/usr/bin/env ruby

macro :section do |node| 
	%{
		<div class="#{node[:macro]}">
			#{node[:value]}
		</div>
	}	
end

macro :header do |node|
	node.get_header
	%{
		<h#{node[:level]} id="#{node[:id]}">#{node[:header]}</h#{node[:level]}>
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

macro_alias :heading => :header
