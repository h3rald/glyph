#!/usr/bin/env ruby

macro :note do
	exact_parameters 1
	%{<div class="#{@name}"><span class="note-title">#{@name.to_s.capitalize}</span>#{@value}

		</div>}
end

macro :box do
	exact_parameters 2
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
	source_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
	dest_file = Glyph.lite? ? image : "images/#{image}"
 	w = (width) ? "width=\"#{width}\"" : ''
	height = @params[2]
 	h = (height) ? "height=\"#{height}\"" : ''
	warning "Image '#{image}' not found" unless Pathname.new(dest_file).exist? 
	%{
		<img src="#{dest_file}" #{w} #{h} alt="-"/>
	}
end

macro :fig do
	min_parameters 1
	max_parameters 2
	image = @params[0]
	caption = @params[1] 
	caption ||= nil
	caption = %{<div class="caption">#{caption}</div>} if caption
	source_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
	dest_file = Glyph.lite? ? image : "images/#{image}"
	warning "Figure '#{image}' not found" unless Pathname.new(dest_file).exist? 
	%{
		<div class="figure">
			<img src="#{dest_file}" alt="-"/>
			#{caption}
		</div>
	}
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
	%{
		<tr>#{@value}	
		</tr>
	}
end

macro :td do
	exact_parameters 1
	%{
		<td>#{@value}
		</td>
	}
end

macro :th do
	exact_parameters 1
	%{
		<th>#{@value}
		</th>
	}
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
