#!/usr/bin/env ruby
# encoding: utf-8

macro :note do
	@data[:name] = @name
	@data[:text] = value
	render
end

macro :box do
	exact_parameters 2
	@data[:title] = param 0
	@data[:text] = param 1
	render
end

macro :codeblock do
	exact_parameters 1 
	@data[:text] = param 0
	render
end

macro :image do
	min_parameters 1
	max_parameters 3
	image = param(0)
	src_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
	dest_file = Glyph.lite? ? image : "images/#{image}"
	warning "Image '#{image}' not found" unless Pathname.new(src_file).exist? 
	@data[:attrs] = @node.attrs
	@data[:src] = Glyph["output.#{Glyph['document.output']}.base"].to_s+dest_file
	render
end

macro :figure do
	min_parameters 1
	max_parameters 2
	image = param(0)
	caption = param(1) rescue nil
	src_file = Glyph.lite? ? image : Glyph::PROJECT/"images/#{image}"
	dest_file = Glyph.lite? ? image : "images/#{image}"
	warning "Figure '#{image}' not found" unless Pathname.new(src_file).exist? 
	@data[:attrs] = @node.attrs
	@data[:src] = Glyph["output.#{Glyph['document.output']}.base"].to_s+dest_file
	@data[:caption] = param(1)
	render
end

macro :title do
	no_parameters
	unless Glyph["document.title"].blank? then
		render
	else
		""
	end
end

macro :subtitle do
	no_parameters
	unless Glyph["document.subtitle"].blank? then
		render
	else
		""
	end
end

macro :author do
	no_parameters
	render
end

# TODO -- document new param!
macro :pubdate do
	max_parameters 1
	@data[:date] = params(0).blank? ? Time.now.strftime("%B %Y") : params(0)
	render
end

macro :revision do
	no_parameters
	unless Glyph["document.revision"].blank? then
		render
	else
		""
	end
end

macro :navigation do
	exact_parameters 1
	topic_id = param(0).to_sym
	base_url = Glyph["output.#{Glyph['document.output']}.base"]
	@data[:contents] = render :link, :target => "#{base_url}index.html", :title => "Contents"
	# Get the previous topic
	previous_topic = @node[:document].topics.last
	if previous_topic then
		@data[:previous] = render :link, :target => "#{base_url}#{previous_topic[:src].gsub(/\..+$/, '.html')}", :title => previous_topic[:title]
	else
		@data[:previous] = ""
	end
	# The next topic is not going to be available yet, use a placeholder
	@data[:next] = placeholder do |document|
		current_topic = document.topics.select{|t| t[:id] == topic_id}[0] rescue nil
		next_topic = document.topics[document.topics.index(current_topic)+1] rescue nil
		render :link, :title => next_topic[:title], :target => "#{base_url}#{next_topic[:src].gsub(/\..+$/, '.html')}" if next_topic
	end
	render
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
