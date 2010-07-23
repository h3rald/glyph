#!/usr/bin/env ruby

macro :anchor do 
	min_parameters 1
	max_parameters 2
	ident = param(0)
	title = param(1) rescue nil
	bookmark :id => ident, :title => title, :file => @source_file
	%{<a id="#{ident}">#{title}</a>}
end

macro :link do
	min_parameters 1
	max_parameters 2
	target = param(0)
	title = param(1) rescue nil
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

macro :fmi do
	exact_parameters 2, :level => :warning
	topic = param(0) 
	href = param(1)
	link = placeholder do |document| 
		interpret "link[#{href}]"
	end
	%{<span class="fmi">for more information on #{topic}, see #{link}</span>}
end

macro :draftcomment do
	if Glyph['document.draft'] then
		%{<span class="comment"><span class="comment-pre"><strong>Comment:</strong> </span>#{value}</span>}
	else
		""
	end
end

macro :todo do
	exact_parameters 1
	todo = {:source => @source_name, :text => value}
	 @node[:document].todos << todo unless @node[:document].todos.include? todo
	if Glyph['document.draft']  then
	 	%{<span class="todo"><span class="todo-pre"><strong>TODO:</strong> </span>#{value}</span>} 
	else
		""
	end
end

macro :topic do
	required_attribute :src
	required_attribute :title
	topic_id = (attr(:id) || "t_#{@node[:document].topics.length}").to_sym
	validate("Macro 'topic' can only be used in document source (#{Glyph['document.source']})") do
		if Glyph['system.topics.ignore_file_restrictions'] then
			true
		else
			@node[:source][:file] == Glyph['document.source']
		end
	end
	n = Glyph::MacroNode.new
	n[:change_topic] = true
	n[:source] = @node[:source]
	n[:name] = :include
	n.children.clear
	p = Glyph::ParameterNode.new.from({:name => :"0"})
	p << Glyph::TextNode.new.from({:value => attr(:src)})
	n << p
	inc_macro = Glyph::Macro.new n
	# Interpret file
	contents = inc_macro.expand	
	if Glyph['document.output'].to_sym.in? Glyph['system.multifile_targets'] then
		# Create topic
		result = interpret %{
		document[
			head[
				style[default.css]
			]
			body[
				section[
					@title[#{attr(:title)}]
					@id[#{topic_id}]
			#{contents}
				]
			]
		]
		}
		# Fix file for topic bookmark
		@node[:document].bookmark?(topic_id).file = attr(:src)
		@node[:document].topics << {:src => attr(:src), :title => attr(:title), :id => topic_id, :contents => result}
		# Return link
		interpret %{link[##{topic_id}|#{attr(:title)}]}
	else
		# Behave exactly like include[]
		contents
	end
end

macro_alias :bookmark => :anchor
macro_alias '#' => :anchor
macro_alias '=>' => :link
macro_alias '!' => :todo
macro_alias :dc => :draftcomment
