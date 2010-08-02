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
				warning "Image '#{image}' not found" unless Pathname.new(src_file).exist? 
				block.call alt, dest_file
			end

			def figure_element_for(image, alt, caption, &block)
				src_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
				dest_file = Glyph.lite? ? image : "images/#{image}"
				warning "Figure '#{image}' not found" unless Pathname.new(src_file).exist? 
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

			def toc_element_for(depth, title, procs={})
				link_header = procs[:link]
				toc = placeholder do |document|
					descend_section = lambda do |n1, added_headers|
						list = ""
						added_headers ||= []
						n1.descend do |n2, level|
							if n2.is_a?(Glyph::MacroNode) && Glyph['system.structure.headers'].include?(n2[:name]) then
								next if n2.find_parent{|node| Glyph['system.structure.special'].include? node[:name] }
								header_hash = n2[:header]
								next if depth && header_hash && (header_hash.level-1 > depth.to_i) || header_hash && !header_hash.toc?
								next if added_headers.include? header_hash
								added_headers << header_hash
								# Check if part of frontmatter, bodymatter or backmatter
								container = n2.find_parent do |node| 
									node.is_a?(Glyph::MacroNode) && 
										node[:name].in?([:frontmatter, :bodymatter, :appendix, :backmatter])
								end[:name] rescue nil
								list << procs[:toc_item].call([container, n2[:name]], link_header.call(header_hash)) if header_hash
								child_list = ""
								n2.children.each do |c|
									child_list << descend_section.call(c, added_headers)
								end	
								list << procs[:toc_sublist].call(child_list) unless child_list.blank?
							end
						end
						list
					end
					title ||= "Table of Contents"
					bmk = bookmark :id => :toc, :file => @source_file, :title => title
					procs[:toc_list].call descend_section, bmk, document
				end
				toc
			end

			def section_element_for(procs={})
				h = ""
				if attr(:title) then
					level = 1
					@node.ascend do |n| 
						if n.is_a?(Glyph::MacroNode) && Glyph["system.structure.headers"].include?(n[:name]) then
							level+=1
						end
					end
					ident = (attr(:id) || "h_#{@node[:document].headers.length+1}").to_sym
					bmk = header :title => attr(:title), :level => level, :id => ident, :toc => !attr(:notoc), :file => @source_file
					@node[:header] = bmk
					h = procs[:title].call level, bmk, attr(:title)
				end
				if attr(:src) then 
					# Create topic
					if Glyph.multiple_output_files? 
						topic_id = (attr(:id) || "t_#{@node[:document].topics.length}").to_sym
						layout = attr(:layout) || Glyph['document.topic_layout'] || :topic
						layout_name = "layout:#{layout}".to_sym
						macro_error "Layout '#{layout}' not found" unless Glyph::MACROS[layout_name]
						@node[:change_topic] = true
						result = interpret %{#{layout_name}[
											@title[#{attr(:title)}]
											@id[#{topic_id}]
											@contents[include[#{attr(:src)}]]
									]}
						# Fix file for topic bookmark
						@node[:document].bookmark?(topic_id).file = attr(:src)
						@node[:document].topics << {:src => attr(:src), :title => attr(:title), :id => topic_id, :contents => result}
						# Return nothing
						nil
					else
						procs[:body].call h, interpret("include[#{attr(:src)}]")
					end
				else
					procs[:body].call h, value
				end
			end

			def navigation_element_for(topic_id, procs)
				# Get the previous topic
				previous_topic = @node[:document].topics.last
				previous_link = procs[:previous].call previous_topic
				# The next topic is not going to be available yet, use a placeholder
				next_link = placeholder do |document|
					current_topic = document.topics.select{|t| t[:id] == topic_id}[0] rescue nil
					next_topic = document.topics[document.topics.index(current_topic)+1] rescue nil
					procs[:next].call next_topic
				end
				contents_link = procs[:contents].call
				procs[:navigation].call contents_link, previous_link, next_link
			end


		end
	end
end
