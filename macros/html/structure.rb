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

# Output:
# <ul class="toc">
# 	<li class="toc-chapter">Test 1</li>
# 	<li class="toc-chapter">Test 2</li>
# 	<li class="toc-chapter">Test 3</li>
# 	<li class="toc-chapter">Test 4</li>
# 	<li>
# 		<ul>
# 			<li class="toc-section">Section 4.1</li>
# 			<li class="toc-section">Section 4.2</li>
# 			<li class="toc-section">Section 4.3</li>
# 		</ul>
# 	</li>
# 	<li class="toc-chapter">Test 5</li>
# </ul>

macro :toc do |node|
	afterwards do
		descend_section = lambda do |n1, added_headers|
			list = ""
			added_headers ||= []
			n1.descend do |n2, level|
				if Glyph::CONFIG.get("structure.headers").include?(n2[:macro])
					header_node = nil
					n2.each_child  do |n| 
						if n[:header] then
							header_node = n
							break
						end
					end
					next if added_headers.include? header_node.to_hash
					added_headers << header_node.to_hash
					list << "<li>#{header_node[:header]}</li>" if header_node
					child_list = ""
					n2.children.each do |c|
						child_list << descend_section.call(c, added_headers)
					end	
					list << "<li><ul>#{child_list}</ul></li>" unless child_list.blank?
				end
			end
			list
		end
		%{<ul class="toc">
				#{descend_section.call(Glyph::DOCUMENT, nil)}
			</ul>}
	end
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
