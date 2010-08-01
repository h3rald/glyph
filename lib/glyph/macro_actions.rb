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

			def xml_draftcomment_for(value)
				if Glyph['document.draft'] then
					%{<span class="comment"><span class="comment-pre"><strong>Comment:</strong> </span>#{value}</span>}
				else
					""
				end
			end

			def xml_todo_for(value)
				todo = {:source => @source_name, :text => value}
				@node[:document].todos << todo unless @node[:document].todos.include? todo
				if Glyph['document.draft']  then
					%{<span class="todo"><span class="todo-pre"><strong>TODO:</strong> </span>#{value}</span>} 
				else
					""
				end
			end




		end
	end
end
