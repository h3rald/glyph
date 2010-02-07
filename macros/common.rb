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
	begin
		ident = node.params[0].to_sym
		raise MacroError.new(node, "Snippet '#{ident}' does not exist") unless Glyph::SNIPPETS.include? ident
		snippet = Glyph::SNIPPETS[ident]
		node[:source] = "snippet: #{node[:value]}"
		i = Glyph::Interpreter.new snippet, node
		i.document.output
	rescue Exception => e
		warning e.message
		"[SNIPPET '#{node[:value]}' NOT FOUND]"
	end
end

macro :include do |node|
	begin
		file = nil
		(Glyph::PROJECT/"text").find do |f|
			file = f if f.to_s.match /\/#{node[:value]}$/
		end	
		raise MacroError.new(node, "File #{node[:value]} no found.") unless file
		contents = file_load file
		if cfg("filters.by_file_extension") then
			begin
				ext = node[:value].match(/\.(.*)$/)[1]
				raise MacroError.new(node, "Macro '#{ext}' not found") unless Glyph::MACROS.include?(ext.to_sym)
				contents = "#{ext}[#{contents}]"
			rescue MacroError => e
				warning e.message
			end
		end	
		node[:source] = "file: #{node[:value]}"
		i = Glyph::Interpreter.new contents, node
		i.document.output
	rescue MacroError => e
		warning e
		"[FILE '#{node[:value]}' NOT FOUND]"
	end
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
