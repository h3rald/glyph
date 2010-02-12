#!/usr/bin/env ruby

macro :note do
	%{
		<div class="#{@name}">
			<span class="note-title">#{@name.to_s.capitalize}</span>
			<span class="note-body">#{@value}</span>
		</div>
	}
end

macro :fig do
	# TODO
	""
end

macro :"textile.code" do
	# TODO
	%{
		<notextile>
		<pre>
		<code>
#{@params[1]}
		</code>
		</pre>
		</notextile>
	}
end

macro :title do
	title_start = (cfg("structure.first_header_level") > 1) ? "<h1>" : %{<div class "title">} 
	title_end = (cfg("structure.first_header_level") > 1) ? "</h1>" : %{</div>} 
	%{
		#{title_start}
			#{cfg("document.title")}
		#{title_end}
	}
end

macro :author do
	%{
		<div class="author">
			#{cfg("document.author")}
		</div>
	}
end

macro :pubdate do
	%{
		<div class="pubdate">
			#{Time.now.strftime("%d %B %Y")}
		</div>
	}
end

macro :table do
	%{<table>#{@value}</table>}
end

macro :tr do
	%{<tr>#{@value}</tr>}
end

macro :td do
	%{<td>#{@value}</td>}
end

macro :th do
	%{<th>#{@value}</th>}
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
