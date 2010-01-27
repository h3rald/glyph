#!/usr/bin/env ruby


macro :comment do |node|
	""
end

macro :snippet do |node|
	node[:source] = "snippet: #{node[:value]}"
	process(node.get_snippet, node)[:output]
end

macro :include do |node|
	contents = node.load_file
	if Glyph::CONFIG.get "filters.by_file_extension" then
		ext = node[:value].match(/\.(.*)$/)[1]
		raise MacroError.new(node, "Macro '#{ext}' not found") unless Glyph::MACROS.include?(ext.to_sym)
		contents = "#{ext}[#{contents}]"
	end	
	node[:source] = "file: #{node[:value]}"
	process(contents, node)[:output]
end

macro :escape do |node| 
	node[:value] 
end

macro :ruby do |node|
	Kernel.instance_eval(node[:value])
end

macro :config do |node|
	Glyph::CONFIG.get node[:value]
end

macro_alias '--' => :comment
macro_alias '&' => :snippet
macro_alias '.' => :escape
macro_alias '@' => :include
macro_alias '%' => :ruby
macro_alias '$' => :config
