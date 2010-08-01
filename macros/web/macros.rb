#!/usr/bin/env ruby

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
	n[:document] = @node[:document]
	p = Glyph::ParameterNode.new.from({:name => :"0"})
	p << Glyph::TextNode.new.from({:value => attr(:src)})
	n << p
	inc_macro = Glyph::Macro.new n
	# Interpret file
	contents = inc_macro.expand	
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
	# Return nothing
	nil
end
