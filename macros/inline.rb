#!/usr/bin/env ruby
# encoding: utf-8

macro :anchor do 
	min_parameters 1
	max_parameters 2
	bookmark :id => param(0), :title => param(1), :file => @source_file
	@data[:id] = param 0
	@data[:title] = param 1
	render
end

macro :link do
	min_parameters 1
	max_parameters 2
	target = param 0 
	title = param 1 
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
				@data[:target] = bmk.link(@source_file)
				@data[:title] = bmk_title
				render
			end
		else
			bmk_title = title
			bmk_title = bmk.title if bmk_title.blank?
			@data[:target] = bmk.link(@source_file)
			@data[:title] = bmk_title
			render
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
		@data[:target] = target
		@data[:title] = title
		render
	end
end

macro :fmi do
	exact_parameters 2, :level => :warning
	topic = param 0
	href = param 1
	link = placeholder do |document| 
		interpret "link[#{href}]"
	end
	@data[:topic] = topic
	@data[:link] = link
	render
end

macro :draftcomment do
	if Glyph['document.draft'] then
		@data[:comment] = value
		render
	else
		""
	end
end

macro :todo do
	exact_parameters 1
	todo = {:source => @source_name, :text => value}
	@node[:document].todos << todo unless @node[:document].todos.include? todo
	if Glyph['document.draft']  then
		@data[:todo] = value
		render
	else
		""
	end
end

macro_alias :bookmark => :anchor
macro_alias '#' => :anchor
macro_alias '=>' => :link
macro_alias '!' => :todo
macro_alias :dc => :draftcomment
