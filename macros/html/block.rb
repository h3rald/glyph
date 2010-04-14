#!/usr/bin/env ruby

macro :note do
	exact_parameters 1
	%{<div class="#{@name}"><span class="note-title">#{@name.to_s.capitalize}</span>#{@value}

		</div>}
end

macro :box do
	exact_parameters 1
	%{<div class="box"><span class="box-title">#{@params[0]}</span>
#{@params[1]}

		</div>}
end

macro :code do
	exact_parameters 1
	%{<div class="code"><pre><code>
#{@value.gsub('>', '&gt;').gsub('<', '&lt;')}
</code></pre></div>}
end

macro :title do
	no_parameters
	%{
		<h1>
			#{cfg("document.title")}
		</h1>
	}
end

macro :img do
	min_parameters 1
	max_parameters 3
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
	min_parameters 1
	max_parameters 3
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
	no_parameters
	%{
		<h2>
			#{cfg("document.subtitle")}
		</h2>
	}
end

macro :author do
	no_parameters
	%{
		<div class="author">
			by <em>#{cfg("document.author")}</em>
		</div>
	}
end

macro :pubdate do
	no_parameters
	%{
		<div class="pubdate">
			#{Time.now.strftime("%B %Y")}
		</div>
	}
end

macro :table do
	exact_parameters 1
	%{
		<table>#{@value}
		</table>
	}
end

macro :tr do
	exact_parameters 1
	allowed_parents :table
	%{
		<tr>#{@value}	
		</tr>
	}
end

macro :td do
	exact_parameters 1
	allowed_parents :tr
	%{
		<td>#{@value}
		</td>
	}
end

macro :th do
	exact_parameters 1
	allowed_parents :tr
	%{
		<th>#{@value}
		</th>
	}
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
