#!/usr/bin/env ruby

macro :section do 
	max_parameters 1
	if raw_attribute(:src) && Glyph.multiple_output_files? then
		required_attribute :title
	end
	procs = {}
	procs[:title] = lambda do |level, ident, title|
		%{<header><h1 id="#{ident}">#{title}</h1></header>\n}	
	end
	procs[:body] = lambda do |title, value|
		%{<section class="#{@name}">
#{title}#{value}

</section>}	
	end
	section_element_for procs
end

macro :article do
	exact_parameters 1
	head = raw_attr(:head)
 	head ||= %{style[default.css]}
	pre_title = raw_attr(:"pre-title")
	post_title = raw_attr(:"post-title")
	pubdate = @node.attr(:pubdate) ? "time[@class[pubdate]#{@node.attr(:pubdate).contents}]" : "pubdate[]"
	halftitlepage = raw_attr(:halftitlepage)
	halftitlepage ||= %{
			#{pre_title}
			hgroup[
				title[]
				subtitle[]
			]
			author[]
			#{pubdate}
			#{post_title}
	}
	interpret %{document[
	head[#{head}]
	body[
		=article[
			halftitlepage[
				#{halftitlepage}
			]
			#{@node.value}
		]
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
	pubdate = @node.attr(:pubdate) ? "time[@class[pubdate]#{@node.attr(:pubdate).contents}]" : "pubdate[]"
	titlepage ||= %{
			#{pre_title}
			hgroup[
				title[]
				subtitle[]
			]
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
	%{<!DOCTYPE html>
<html lang="en">
#{value}

</html>}
end

macro :toc do 
	max_parameters 1
	link_proc = lambda do |head|
		%{<a href="#{head.link(@source_file)}">#{head.title}</a>}
	end
	toc_list_proc = lambda do |descend_proc, bmk, document|
		%{<nav class="contents">
<h1 class="toc-header" id="#{bmk}">#{bmk.title}</h1>
<ol class="toc">
						#{descend_proc.call(document.structure, nil)}
</ol>
</nav>}
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
