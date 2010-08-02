#!/usr/bin/env ruby

macro :note do
	%{<aside class="#{@name}">
<span class="note-title">#{@name.to_s.capitalize}</span>#{value}

</aside>}
end

macro :box do
	exact_parameters 2
	%{<aside class="box">
<div class="box-title">#{param(0)}</div>
#{param(1)}

</aside>}
end

macro :figure do
	min_parameters 1
	max_parameters 2
	image = param(0)
	alt = "@alt[-]" unless attr(:alt)
	caption = "figcaption[#{param(1)}]" rescue nil
	figure_element_for image, alt, caption do |alt, dest_file, caption|
		interpret %{=figure[
img[#{alt}@src[#{Glyph['document.base']}#{dest_file}]#{@node.attrs.join}]
					#{caption}
]}
	end
end

macro :pubdate do
	no_parameters
	t = Time.now
	%{<time class="pubdate" datetime="#{t.strftime("%Y-%m-%d")}">
#{Time.now.strftime("%B %Y")}
</time>}
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note