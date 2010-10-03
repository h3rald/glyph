module Glyph
	class Macro

		# This module includes some output-agnostic methods used by the most common Glyph macros.
		# @since 0.4.0
		module Helpers

			# Renders a link
			# @param [String] target the target of the link
			# @param[String] title the title of the link
			# @yield [link_path, link_title] the block to call to render the link
			# @yieldparam [String] link_path the path to the link target
			# @yieldparam [String] link_title the title of the link
			def link_element_for(target, title, &block)
				if target.match /^#/ then
					@node[:document].links << target 
					anchor = target.gsub /^#/, ''
					bmk = bookmark? anchor
					if !bmk then
						placeholder do |document|
							bmk = document.bookmark?(anchor)
							macro_error "Bookmark '#{anchor}' does not exist" unless bmk
							bmk_title = title
							bmk_title = bmk.title if bmk_title.blank?
							block.call bmk.link(@source_file), bmk_title
						end
					else
						bmk_title = title
						bmk_title = bmk.title if bmk_title.blank?
						block.call bmk.link(@source_file), bmk_title
					end
				else
					if Glyph['options.url_validation'] && !@node[:document].links.include?(target) then
						begin
							url = URI.parse(target.gsub(/\\\./, ''))
						rescue Exception => e
							macro_warning "Invalid URL: #{url||target}", e
						end
						response = Net::HTTP.get_response(url)
						debug "Checking link URL: #{url} (#{response.code})"
						if response.code.to_i > 302 then
							macro_warning "Linked URL '#{url}' returned status #{response.code} (#{response.message})"
						end
					end
					@node[:document].links << target 
					title ||= target
					block.call target, title
				end
			end

			# Renders a For More Information note
			# @param [String] topic the topic of the note
			# @param [String] href the reference to link to
			# @yield [topic, link] the block used to render the FMI note
			def fmi_element_for(topic, href, &block)
				link = placeholder do |document| 
					interpret "link[#{href}]"
				end
				block.call topic, link
			end

			# Renders a draft comment element
			# @yield [value] the block used to render the comment
			# @yieldparam [String] value the comment text
			def draftcomment_element(&block)
				if Glyph['document.draft'] then
					block.call value
				else
					""
				end
			end

			# Renders a todo element
			# @yield [value] the block used to render the todo element 
			# @yieldparam [String] value the todo text
			def todo_element(&block)
				todo = {:source => @source_name, :text => value}
				@node[:document].todos << todo unless @node[:document].todos.include? todo
				if Glyph['document.draft']  then
					block.call value
				else
					""
				end
			end

			# Renders an image element
			# @param [String] image the image to render
			# @param [String] alt the value of the image's ALT tag
			# @yield [alt, dest_file] the block used to render the image
			def image_element_for(image, alt, &block)
				src_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
				dest_file = Glyph.lite? ? image : "images/#{image}"
				warning "Image '#{image}' not found" unless Pathname.new(src_file).exist? 
				block.call alt, dest_file
			end

			# Renders a figure element
			# @param [String] image the image to render
			# @param [String] alt the value of the image's ALT tag
			# @param [String] caption
			# @yield alt, dest_file, caption] the block used to render the figure
			def figure_element_for(image, alt, caption, &block)
				src_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
				dest_file = Glyph.lite? ? image : "images/#{image}"
				warning "Figure '#{image}' not found" unless Pathname.new(src_file).exist? 
				block.call alt, dest_file, caption
			end

			# Renders a title element
			def title_element(&block)
				unless Glyph["document.title"].blank? then
					block.call
				else
					""
				end
			end

			# Renders a subtitle element
			def subtitle_element(&block)
				unless Glyph["document.subtitle"].blank? then
					block.call
				else
					""
				end
			end

			# Renders an author element
			def author_element(&block)
				unless Glyph['document.author'].blank? then
					block.call
				else
					""
				end
			end

			# Renders a revision element
			def revision_element(&block)
				unless Glyph["document.revision"].blank? then
					block.call
				else
					""
				end
			end

			# Renders a Table of Contents
			# @param [Integer] depth the maximum header level
			# @param [String] title the title of the TOC
			# @param [Hash] procs the Proc objects used to render the TOC
			# @option procs [Proc] :link used to render TOC header links (parameters: Glyph::Header). 
			# @option procs [Proc] :toc_list used to render the TOC list (parameters: a Proc used to traverse the document tree, the Glyph::Bookmark used for the TOC header, a Glyph::Document)
			# @option procs [Proc] :toc_item used to render a TOC item (parameters: an Array of header classes, a String used for the header link)
			# @option procs [Proc] :toc_sublist used to render a TOC sublist (parameters: a String containing the contents of the list)
			def toc_element_for(depth, title, procs={})
				return @node[:document].toc[:contents] if @node[:document].toc[:contents]
				link_header = procs[:link]
				toc = placeholder do |document|
					descend_section = lambda do |n1, added_headers|
						list = ""
						added_headers ||= []
						n1.descend do |n2, level|
							#if n2.is_a?(Glyph::MacroNode) && Glyph['system.structure.headers'].include?(n2[:name]) then
							if n2.is_a?(Glyph::MacroNode) && Glyph.macro_eq?(n2[:name], :section) then
								if Glyph.multiple_output_files? then
									# Only consider topics/booklets when building TOC for web/web5
									next if !n2.attribute(:src) && n2.child_macros.select{|child| child.attribute(:src)}.blank? 
								end
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
					bmk = @node[:document].bookmark?(:toc) || bookmark(:id => :toc, :file => @source_file, :title => title)
					procs[:toc_list].call descend_section, bmk, document
				end
				@node[:document].toc[:contents] = toc.to_s
				toc
			end

			# Renders a section element
			# @param [Hash] procs the Proc objects used to render the section
			# @option procs [Proc] :title used to render the section header (parameters: the header level, the section ID, the section title)
			# @option procs [Proc] :body used to render the section body (parameters: the section title, the section body)
			def section_element_for(procs={})
				h = ""
				if attr(:title) then
					level = 1
					@node.ascend do |n| 
						break if n.respond_to?(:attribute) && n.attribute(:class) && n.attribute(:class).children.join.strip == "topic"
						#if n.is_a?(Glyph::MacroNode) && Glyph["system.structure.headers"].include?(n[:name]) then
						if n.is_a?(Glyph::MacroNode) && Glyph.macro_eq?(n[:name], :section) then
							level+=1
						end
					end
					ident = (attr(:id) || "h_#{@node[:document].headers.length+1}").to_sym
					# The bookmark is added when the section is first processed; therefore it will exist already when a topic layout is processed
					bmk = @node[:document].bookmark?(ident)
					bmk ||=  header	:title => attr(:title), 
													:level => level, 
													:id => ident, 
													:toc => !attr(:notoc),
													:definition => @source_file,
													:file => (attr(:src) || @source_file)
					@node[:header] = bmk
					h = procs[:title].call level, bmk, attr(:title)
				end
				if attr(:src) then 
					# Create topic
					if Glyph.multiple_output_files? 
						topic_id = (attr(:id) || "t_#{@node[:document].topics.length}").to_sym
						layout = attr(:layout) || Glyph["output.#{Glyph['document.output']}.layouts.topic"] || :topic
						layout_name = "layout:#{layout}".to_sym
						macro_error "Layout '#{layout}' not found" unless Glyph::MACROS[layout_name]
						result = interpret %{#{layout_name}[
											@title[#{attr(:title)}]
											@id[#{topic_id}]
											@contents[include[@topic[true]#{attr(:src)}]]
									]}
						bmk = @node[:document].bookmark? topic_id
						if bmk then
							# Fix file for topic bookmark
							@node[:document].bookmark?(topic_id).file = attr(:src)
						else
							bookmark :title => attr(:title), :id => topic_id, :file => attr(:src), :definition => @source_file
						end
						topic_src = attr(:src)
						topic_src += ".glyph" unless topic_src.match /\..+$/
						@node[:document].topics << {:src => topic_src, :title => attr(:title), :id => topic_id, :contents => result}
						# Process section contents
						procs[:body].call h, value
						# Return nothing
						nil
					else
						v = raw_value
						@node.children.delete_if{|c| !c.is_a?(Glyph::AttributeNode)}
						body = interpret "include[#{attr(:src)}]#{v}"
						procs[:body].call h, body
					end
				else
					procs[:body].call h, value
				end
			end

			# Renders a navigation element
			# @param [String] topic_id the ID of the current topic
			# @param [Hash] procs the Proc objects used to render the navigation element
			#	@option procs [Proc] :previous the link to the previous topic
			#	@option procs [Proc] :next the link to the next topic 
			#	@option procs [Proc] :contents the link to the document contents 
			def navigation_element_for(topic_id, procs={})
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
