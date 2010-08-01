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

			def image_element_for(image, alt, &block)
				src_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
				dest_file = Glyph.lite? ? image : "images/#{image}"
				Glyph.warning "Image '#{image}' not found" unless Pathname.new(src_file).exist? 
				block.call alt, dest_file
			end

			def figure_element_for(image, alt, caption, &block)
				src_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
				dest_file = Glyph.lite? ? image : "images/#{image}"
				Glyph.warning "Figure '#{image}' not found" unless Pathname.new(src_file).exist? 
				block.call alt, dest_file, caption
			end

			def title_element(&block)
				unless Glyph["document.title"].blank? then
					block.call
				else
					""
				end
			end

			def subtitle_element(&block)
				unless Glyph["document.subtitle"].blank? then
					block.call
				else
					""
				end
			end

			def author_element(&block)
				unless Glyph['document.author'].blank? then
					block.call
				else
					""
				end
			end

			def revision_element(&block)
				unless Glyph["document.revision"].blank? then
					block.call
				else
					""
				end
			end

		end
	end
end
