#!/usr/bin/env ruby

macro :note do |node|
	%{
		<div class="#{node[:macro]}">
			<span class="note-title">#{node[:macro].capitalize}</span>
			<span class="note-body">#{node[:value]}</span>
		</div>
	}
end

macro :fig do |node|
	# TODO
	""
end

macro :"textile.code" do |node|
	# TODO
	params = node.get_params
	%{
		<notextile>
		<pre>
		<code>
#{params[1]}
		</code>
		</pre>
		</notextile>
	}
end

macro :title do |node|
	title_start = (cfg("structure.first_header_level") > 1) ? "<h1>" : %{<div class "title">} 
	title_end = (cfg("structure.first_header_level") > 1) ? "</h1>" : %{</div>} 
	%{
		#{title_start}
			#{cfg("document.title")}
		#{title_end}
	}
end

macro :author do |node|
	%{
		<div class="author">
			#{cfg("document.author")}
		</div>
	}
end

macro :pubdate do |node|
	%{
		<div class="pubdate">
			#{Time.now.strftime("%d %B %Y")}
		</div>
	}
end

macro :table do |node|
	%{<table>#{node[:value]}</table>}
end

macro :tr do |node|
	%{<tr>#{node[:value]}</tr>}
end

macro :td do |node|
	%{<td>#{node[:value]}</td>}
end

macro :th do |node|
	%{<th>#{node[:value]}</th>}
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
