#!/usr/bin/env ruby

macro :topic do
	within :contents
	not_within :topic
	required_attribute :src
	required_attribute :title
	topic_id = (attr(:id) || "t_#{@node[:document].topics.length}").to_sym
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
	layout = attr(:layout) || Glyph['document.topic_layout'] || :topic
	layout_name = "layout:#{layout}".to_sym
	macro_error "Layout '#{layout}' not found" unless Glyph::MACROS[layout_name]
	result = interpret %{#{layout_name}[
			@title[#{attr(:title)}]
			@id[#{topic_id}]
			@contents[#{contents}]
		]
	}
	# Fix file for topic bookmark
	@node[:document].bookmark?(topic_id).file = attr(:src)
	@node[:document].topics << {:src => attr(:src), :title => attr(:title), :id => topic_id, :contents => result}
	# Return nothing
	nil
end
