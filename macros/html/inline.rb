#!/usr/bin/env ruby

macro :anchor do 
	min_parameters 1
	max_parameters 2
	ident = param(0)
	title = param(1) rescue nil
	bmk = bookmark :id => ident, :title => title, :file => @source_file
	%{<a id="#{bmk.ref}">#{title}</a>}
end

macro :link do
	min_parameters 1
	max_parameters 2
	href = param(0)
	title = param(1) rescue nil
	if href.match /^#/ then
		file, anchor = href.split '#'
		file = @source_file if file.blank?
		bmk = bookmark? anchor, file
		href = Glyph::Bookmark.new(:id => anchor, :file => file).link
		if bmk then
			title ||= bmk.title
		else
			plac = placeholder do |document|
				macro_error "Bookmark '#{anchor}' does not exist" unless bookmark? anchor, file 
				bookmark?(anchor, file).title
			end
			title ||= plac
		end
	end
	title ||= href
	%{<a href="#{href}">#{title.to_s}</a>}
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

macro_alias :bookmark => :anchor
macro_alias '#' => :anchor
macro_alias '=>' => :link
macro_alias '!' => :todo
macro_alias :dc => :draftcomment
