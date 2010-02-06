#!/usr/bin/env ruby


macro :comment do |node|
	""
end

macro :todo do |node|
	todo = "[#{node[:source]}] -- #{node[:value]}"
	Glyph::TODOS << todo unless Glyph::TODOS.include? todo
	""
end

macro :snippet do |node|
	node[:source] = "snippet: #{node[:value]}"
	i = Glyph::Interpreter.new node.snippet, node
	i.document.output
end

macro :include do |node|
	contents = node.load_file
	if cfg("filters.by_file_extension") then
		ext = node[:value].match(/\.(.*)$/)[1]
		raise MacroError.new(node, "Macro '#{ext}' not found") unless Glyph::MACROS.include?(ext.to_sym)
		contents = "#{ext}[#{contents}]"
	end	
	node[:source] = "file: #{node[:value]}"
	i = Glyph::Interpreter.new contents, node
	i.document.output
end

macro :escape do |node| 
	node[:value] 
end

macro :ruby do |node|
	Kernel.instance_eval(node[:value])
end

macro :config do |node|
	cfg node[:value]
end

macro_alias '--' => :comment
macro_alias '&' => :snippet
macro_alias '.' => :escape
macro_alias '@' => :include
macro_alias '%' => :ruby
macro_alias '$' => :config
