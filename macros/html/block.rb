#!/usr/bin/env ruby

macro :note do
	%{<div class="#{@name}">
<span class="note-title">#{@name.to_s.capitalize}</span>#{value}

</div>}
end

macro :box do
	exact_parameters 2, :level => :warning
	%{<div class="box">
<div class="box-title">#{params[0]}</div>
#{params[1]}

</div>}
end

macro :code do
	min_parameters 1 
	%{
<div class="code">
<pre>
<code>
#{raw_value}
</code>
</pre>
</div>}
end

macro :highlight do
	min_parameters 2  
	lang = params[0]
	text = params(:strip => false)[1..params.length-1].join '\\|'
	text.gsub!(/\\(.)/){$1}
	highlighter = Glyph["highlighters.current"].to_sym rescue nil
	if !highlighter then
		begin
			require 'coderay'
			highlighter = :coderay
		rescue LoadError
			begin 
				require 'uv'
				highlighter = :ultraviolet
			rescue LoadError
				macro_error "No highlighter installed. Please run: gem install coderay"
			end
		end
		Glyph["highlighter.current"] = highlighter
	end
	target = Glyph["highlighters.target"]
	result = ""
	case highlighter.to_sym
	when :coderay
		begin
			require 'coderay'
			result = CodeRay.scan(text, lang).div(Glyph["highlighters.coderay"])
		rescue LoadError
			macro_error "CodeRay highlighter not installed. Please run: gem install coderay"
		rescue Exception => e
			macro_error e.message
		end
	when :ultraviolet
		begin
			require 'uv'
			target = 'xhtml' if target == 'html'
			result = Uv.parse(text.to_s, target.to_s, lang.to_s, 
							 Glyph["highlighters.ultraviolet.line_numbers"], 
							 Glyph["highlighters.ultraviolet.theme"].to_s)
		rescue LoadError
			macro_error "UltraViolet highlighter not installed. Please run: gem install ultraviolet"
		rescue Exception => e
			puts e.backtrace
			macro_error e.message
		end
	else
		macro_error "No highlighter installed. Please run: gem install coderay"
	end
	result
end

macro :title do
	no_parameters
	%{<h1>
			#{Glyph["document.title"]}
</h1>}
end

macro :img do
	min_parameters 1
	max_parameters 3
	image = params[0]
	width = params[1]
	source_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
	dest_file = Glyph.lite? ? image : "images/#{image}"
 	w = (width) ? "width=\"#{width}\"" : ''
	height = params[2]
 	h = (height) ? "height=\"#{height}\"" : ''
	Glyph.warning "Image '#{image}' not found" unless Pathname.new(dest_file).exist? 
	%{<img src="#{dest_file}" #{w} #{h} alt="-"/>}
end

macro :fig do
	min_parameters 1
	max_parameters 2
	image = params[0]
	caption = params[1] 
	caption ||= nil
	caption = %{<div class="caption">#{caption}</div>} if caption
	source_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
	dest_file = Glyph.lite? ? image : "images/#{image}"
	Glyph.warning "Figure '#{image}' not found" unless Pathname.new(dest_file).exist? 
	%{<div class="figure">
<img src="#{dest_file}" alt="-"/>
#{caption}
</div>}
end


macro :subtitle do
	no_parameters
	%{<h2>
#{Glyph["document.subtitle"]}
</h2>}
end

macro :author do
	no_parameters
	%{<div class="author">
by <em>#{Glyph["document.author"]}</em>
</div>}
end

macro :pubdate do
	no_parameters
	%{<div class="pubdate">
#{Time.now.strftime("%B %Y")}
</div>}
end

macro :table do
	exact_parameters 1
	%{<table>
#{value}
</table>}
end

macro :tr do
	exact_parameters 1, :level => :warning
	%{<tr>
#{value}	
</tr>}
end

macro :td do
	exact_parameters 1, :level => :warning
	%{<td>
#{value}

</td>}
end

macro :th do
	exact_parameters 1, :level => :warning
	%{<th>#{value}</th>}
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
