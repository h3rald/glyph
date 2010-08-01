module Glyph
	class Macro

		# @since 0.4.0
		module Actions

			def xml_link_for(target, title)
				if target.match /^#/ then
					anchor = target.gsub /^#/, ''
					bmk = bookmark? anchor
					if !bmk then
						placeholder do |document|
							bmk = document.bookmark?(anchor)
							macro_error "Bookmark '#{anchor}' does not exist" unless bmk
							%{<a href="#{bmk.link(@source_file)}">#{bmk.title}</a>}
						end
					else
						%{<a href="#{bmk.link(@source_file)}">#{bmk.title}</a>}
					end
				else
					title ||= target
					%{<a href="#{target}">#{title}</a>}
				end
			end

			def xml_fmi_for(topic, href)
				link = placeholder do |document| 
					interpret "link[#{href}]"
				end
				%{<span class="fmi">for more information on #{topic}, see #{link}</span>}
			end

			def xml_bookmark_for(ident, title)
				bookmark :id => ident, :title => title, :file => @source_file
				%{<a id="#{ident}">#{title}</a>}
			end

			def xml_draftcomment
				if Glyph['document.draft'] then
					%{<span class="comment"><span class="comment-pre"><strong>Comment:</strong> </span>#{value}</span>}
				else
					""
				end
			end

			def xml_todo
				todo = {:source => @source_name, :text => value}
				@node[:document].todos << todo unless @node[:document].todos.include? todo
				if Glyph['document.draft']  then
					%{<span class="todo"><span class="todo-pre"><strong>TODO:</strong> </span>#{value}</span>} 
				else
					""
				end
			end

			def xml_note
				%{<div class="#{@name}">
<span class="note-title">#{@name.to_s.capitalize}</span>#{value}

</div>}
			end

			def xml_box
				%{<div class="box">
<div class="box-title">#{param(0)}</div>
#{param(1)}

</div>}
			end

			def xml_codeblock
				%{
<div class="code">
<pre>
<code>
#{value}
</code>
</pre>
</div>}
			end

			def xml_image_for(image, alt)
				src_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
				dest_file = Glyph.lite? ? image : "images/#{image}"
				Glyph.warning "Image '#{image}' not found" unless Pathname.new(src_file).exist? 
				interpret "img[#{alt}@src[#{Glyph['document.base']}#{dest_file}]#{@node.attrs.join}]"
			end

			def xml_figure_for(image, alt, caption)
				caption = "div[@class[caption]#{caption}]" if caption
				src_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
				dest_file = Glyph.lite? ? image : "images/#{image}"
				Glyph.warning "Figure '#{image}' not found" unless Pathname.new(src_file).exist? 
				interpret %{div[@class[figure]
img[#{alt}@src[#{Glyph['document.base']}#{dest_file}]#{@node.attrs.join}]
					#{caption}
]}
			end

			def xml_title
				unless Glyph["document.title"].blank? then
					%{<h1>
						#{Glyph["document.title"]}
</h1>}
				else
					""
				end
			end

			def xml_subtitle
				unless Glyph["document.subtitle"].blank? then
					%{<h2>
						#{Glyph["document.subtitle"]}
</h2>}
				else
					""
				end
			end

			def xml_author
				unless Glyph['document.author'].blank? then
					%{<div class="author">
by <em>#{Glyph["document.author"]}</em>
</div>}
				else
					""
				end
			end

			def xml_pubdate
				%{<div class="pubdate">
#{Time.now.strftime("%B %Y")}
</div>}
			end
			
			def xml_revision
				unless Glyph["document.revision"].blank? then
					%{<div class="revision">#{Glyph['document.revision']}</div>}
				else
					""
				end
			end










		end
	end
end
