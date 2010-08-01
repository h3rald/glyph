module Glyph
	class Macro

		# @since 0.4.0
		module Helpers

			def link_element_for(target, title, &block)
				if target.match /^#/ then
					anchor = target.gsub /^#/, ''
					bmk = bookmark? anchor
					if !bmk then
						placeholder do |document|
							bmk = document.bookmark?(anchor)
							macro_error "Bookmark '#{anchor}' does not exist" unless bmk
							block.call bmk.link(@source_file), bmk.title
						end
					else
						block.call bmk.link(@source_file), bmk.title
					end
				else
					title ||= target
					block.call target, title
				end
			end

			def fmi_element_for(topic, href, &block)
				link = placeholder do |document| 
					interpret "link[#{href}]"
				end
				block.call topic, link
			end

			def draftcomment_element(&block)
				if Glyph['document.draft'] then
					block.call value
				else
					""
				end
			end

			def todo_element(&block)
				todo = {:source => @source_name, :text => value}
				@node[:document].todos << todo unless @node[:document].todos.include? todo
				if Glyph['document.draft']  then
					block.call value
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
