#!/usr/bin/env ruby
# encoding: utf-8

reps_for :html

# Inline

rep :fmi do |data|
	%{<span class="fmi">for more information on <mark>#{data[:topic]}</mark>, see #{data[:link]}</span>}
end

rep :draftcomment do |data|
	%{<aside class="comment"><span class="comment-pre"><strong>Comment:</strong> </span>#{data[:comment]}</aside>}
end

rep :todo do |data|
	%{<aside class="todo"><span class="todo-pre"><strong>TODO:</strong> </span>#{data[:todo]}</aside>} 
end

# Block

rep :note do |data|
	%{<aside class="#{data[:name]}">
<span class="note-title">#{data[:name].capitalize}</span>#{data[:text]}

</aside>}
end

rep :box do |data|
	%{<aside class="box">
<div class="box-title">#{data[:title]}</div>
#{data[:text]}

</aside>}
end

# TODO: change fallback
rep :figure do |data|
	interpret %{xml/figure[
xml/img[@src[#{data[:src]}]#{data[:attrs].join}]
					xml/figcaption[#{data[:caption]}]
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
	%{<time class="pubdate"  datetime="#{Time.now.strftime("%Y-%m-%d")}">
#{data[:date]}
</time>}
end

rep :revision do |data|
	%{<div class="revision">#{Glyph['document.revision']}</div>}
end

rep :navigation do |data|
	%{<nav class="navigation">#{data[:previous]} | #{data[:contents]} | #{data[:next]}</nav>}
end

# Structure

rep :document do |data|
	%{<!DOCTYPE html>
<html lang="en">
#{data[:content]}

</html>}
end

rep :toc do |data|
	%{<nav class="contents">
<h1 class="toc-header" id="#{data[:toc_id]}">#{data[:title]}</h1>
<ol class="toc">
						#{data[:descend_section].call(data[:document].structure, nil)}
</ol>
</nav>}
end

rep :section do |data|
	title = data[:title] ? %{<header><h1 id="#{data[:id]}">#{data[:title]}</h1></header>\n} : ""
	%{<section class="#{data[:name]}">
#{title}#{data[:content]}

</section>}	
end
