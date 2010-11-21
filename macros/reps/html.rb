#!/usr/bin/env ruby
# encoding: utf-8

# Inline

rep :link do |data|
	%{<a href="#{data[:target]}">#{data[:title]}</a>}
end

rep :anchor do |data|
	%{<a id="#{data[:id]}">#{data[:title]}</a>}
end

rep :fmi do |data|
	%{<span class="fmi">for more information on #{data[:topic]}, see #{data[:link]}</span>}
end

rep :draftcomment do |data|
	%{<span class="comment"><span class="comment-pre"><strong>Comment:</strong> </span>#{data[:comment]}</span>}
end

rep :todo do |data|
	%{<span class="todo"><span class="todo-pre"><strong>TODO:</strong> </span>#{data[:todo]}</span>} 
end

# Block

rep :note do |data|
	%{<div class="#{data[:name]}">
<span class="note-title">#{data[:name].to_s.capitalize}</span>#{data[:text]}

</div>}
end

rep :box do |data|
	%{<div class="box">
<div class="box-title">#{data[:title]}</div>
#{data[:text]}

</div>}
end

rep :codeblock do |data|
	%{
<div class="code">
<pre>
<code>
#{data[:text]}
</code>
</pre>
</div>}
end

rep :image do |data|
	interpret "img[@src[#{data[:src]}]#{data[:attrs].join}]"
end

rep :figure do |data|
	interpret %{div[@class[figure]
img[@src[#{data[:src]}]#{data[:attrs].join}]
					div[@class[caption]#{data[:caption]}]
]}
end

rep :title do |data|
	%{<h1>
	#{Glyph["document.title"]}
</h1>}
end

rep :subtitle do |data|
	%{<h2>
	#{Glyph["document.subtitle"]}
</h2>}
end

rep :author do |data|
	%{<div class="author">
by <em>#{Glyph["document.author"]}</em>
</div>}
end

rep :pubdate do |data|
	%{<div class="pubdate">
#{data[:date]}
</div>}
end

rep :revision do |data|
	%{<div class="revision">#{Glyph['document.revision']}</div>}
end

rep :navigation do |data|
	%{<div class="navigation">#{data[:previous]} | #{data[:contents]} | #{data[:next]}</div>}
end

# Structure

rep :document do |data|
	%{<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
#{data[:content]}

</html>}
end

rep :meta do |data|
 %{<meta name="#{data[:name]}" content="#{data[:content]}" />}
end

rep :head do |data|
	%{<head>
<title>#{Glyph["document.title"]}</title>
#{data[:author]}
#{data[:copyright]}
<meta name="generator" content="Glyph v#{Glyph::VERSION} (http://www.h3rald.com/glyph)" />
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
#{data[:content]}
</head>
}
end

rep :style do |data|
	file = data[:file]
	case Glyph['document.styles'].to_s
	when 'embed' then
		style = ""
		case file.extname
		when ".css" then
			style = file_load file
		when ".sass", ".scss" then
			begin
				require 'sass'
				style = Sass::Engine.new(file_load(file), :syntax => file.extname.gsub(/^\./, '').to_sym).render
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
		%{<link href="#{Glyph["output.#{Glyph['document.output']}.base"]}styles/#{value.gsub(/\..+$/, '.css')}" rel="stylesheet" type="text/css" />}
	else
		macro_error "Value '#{Glyph['document.styles']}' not allowed for 'document.styles' setting"
	end
end

rep :toc do |data|
	%{<div class="contents">
<h2 class="toc-header" id="#{data[:toc_id]}">#{data[:title]}</h2>
<ol class="toc">
						#{data[:descend_section].call(data[:document].structure, nil)}
</ol>
</div>}
end

rep :toc_item do |data|
	"<li class=\"#{data[:classes].join(" ").strip}\">#{data[:title]}</li>"
end

rep :toc_sublist do |data|
	"<li><ol>#{data[:contents]}</ol></li>\n"
end

rep :section do |data|
	title = data[:title] ? %{<h#{data[:level]} id="#{data[:id]}">#{data[:title]}</h#{data[:level]}>\n} : ""
	%{<div class="#{data[:name]}">
#{title}#{data[:content]}

</div>}	
end
