#!/usr/bin/env ruby

macro :note do
	%{<div class="#{@name}"><span class="note-title">#{@name.to_s.capitalize}</span>#{@value}

		</div>}
end

macro :box do
	%{<div class="box"><span class="box-title">#{@params[0]}</span>
#{@params[1]}

		</div>}
end

macro :code do
	%{<div class="code"><pre><code>
#{@value.gsub('>', '&gt;').gsub('<', '&lt;')}
</code></pre></div>}
end

macro :title do
	%{
		<h1>
			#{cfg("document.title")}
		</h1>
	}
end

macro :img do
	image = @params[0]
	width = @params[1]
 	w = (width) ? "width=\"#{width}\"" : ''
	height = @params[2]
 	h = (height) ? "height=\"#{height}\"" : ''
	if (Glyph::PROJECT/"images/#{image}").exist? then
		%{
			<img src="images/#{image}" #{w} #{h} alt="-"/>
		}
	else
		warning "Image '#{image}' not found"
		""
	end
end

macro :fig do
	image = @params[0]
	caption = @params[1] 
	caption ||= nil
	caption = %{<div class="caption">#{caption}</div>} if caption
	if (Glyph::PROJECT/"images/#{image}").exist? then
		%{
			<div class="figure">
				<img src="images/#{image}" alt="-"/>
				#{caption}
			</div>
		}
	else
		warning "Figure '#{image}' not found"
		""
	end
end


macro :subtitle do
	%{
		<h2>
			#{cfg("document.subtitle")}
		</h2>
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
		<table>#{@value}
		</table>
	}
end

macro :tr do
	%{
		<tr>#{@value}	
		</tr>
	}
end

macro :td do
	%{
		<td>#{@value}
		</td>
	}
end

macro :th do
	%{
		<th>#{@value}
		</th>
	}
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
