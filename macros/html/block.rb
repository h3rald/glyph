#!/usr/bin/env ruby

macro :note do
	%{<div class="#{@name}">
<span class="note-title">#{@name.to_s.capitalize}</span>#{value}

</div>}
end

macro :box do
	exact_parameters 2
	%{<div class="box">
<div class="box-title">#{param(0)}</div>
#{param(1)}

</div>}
end

macro :codeblock do
	exact_parameters 1 
	%{
<div class="code">
<pre>
<code>
#{value}
</code>
</pre>
</div>}
end

macro :image do
	min_parameters 1
	max_parameters 3
	image = param(0)
	alt = "@alt[-]" unless attr(:alt)
	image_element_for image, alt do |alt, dest_file|
		interpret "img[#{alt}@src[#{Glyph['document.base']}#{dest_file}]#{@node.attrs.join}]"
	end
end

macro :figure do
	min_parameters 1
	max_parameters 2
	image = param(0)
	alt = "@alt[-]" unless attr(:alt)
	caption = "div[@class[caption]#{param(1)}]" rescue nil
	figure_element_for image, alt, caption do |alt, dest_file, caption|
		interpret %{div[@class[figure]
img[#{alt}@src[#{Glyph['document.base']}#{dest_file}]#{@node.attrs.join}]
					#{caption}
]}
	end
end

macro :title do
	no_parameters
	title do
		%{<h1>
	#{Glyph["document.title"]}
</h1>}
	end
end

macro :subtitle do
	no_parameters
	subtitle_element do 
		%{<h2>
	#{Glyph["document.subtitle"]}
</h2>}
	end
end

macro :author do
	no_parameters
	author_element do 
		%{<div class="author">
by <em>#{Glyph["document.author"]}</em>
</div>}
	end
end

macro :pubdate do
	no_parameters
	%{<div class="pubdate">
#{Time.now.strftime("%B %Y")}
</div>}
end

macro :revision do
	no_parameters
	revision_element do
		%{<div class="revision">#{Glyph['document.revision']}</div>}
	end
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
