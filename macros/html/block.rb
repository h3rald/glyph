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
	image = @params[0]
	caption = @params[1] 
	caption ||= nil
	caption = %{<div class="caption">#{caption}</div>} if caption
	source_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
	dest_file = Glyph.lite? ? image : "images/#{image}"
	warning "Figure '#{image}' not found" unless Pathname.new(dest_file).exist? 
	%{
		<div class="figure">
			<img src="images/#{image}" alt="-"/>
			#{caption}
		</div>
	}
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
	allowed_parents :table
	%{
		<tr>#{@value}	
		</tr>
	}
end

macro :td do
	allowed_parents :tr
	%{
		<td>#{@value}
		</td>
	}
end

macro :th do
	allowed_parents :tr
	%{
		<th>#{@value}
		</th>
	}
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
