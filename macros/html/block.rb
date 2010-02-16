#!/usr/bin/env ruby

macro :note do
	%{
		<div class="#{@name}">
			<span class="note-title">#{@name.to_s.capitalize}</span>
			#{@value}

		</div>
	}
end

macro :box do
	%{
		<div class="box">
			<span class="box-title">#{@params[0]}</span>
		#{@params[1]}

		</div>
	}
end

macro :fig do
	# TODO
	""
end

macro :"textile.code" do
	# TODO
	%{<div class="code"><notextile><pre><code>#{@params[1]}</code></pre></notextile></div>}
end

macro :title do
	%{
		<h1>
			#{cfg("document.title")}
		</h1>
	}
end

macro :author do
	%{
		<div class="author">
			by <em>#{cfg("document.author")}</em>
		</div>
	}
end

macro :pubdate do
	%{
		<div class="pubdate">
			#{Time.now.strftime("%B %Y")}
		</div>
	}
end

macro :table do
	%{
		<table>
		#{@value}
		
		</table>
	}
end

macro :tr do
	%{
		<tr>
		#{@value}
		
		</tr>
	}
end

macro :td do
	%{
		<td>
		#{@value}
		
		</td>
	}
end

macro :th do
	%{
		<th>
		#{@value}

		</th>
	}
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
