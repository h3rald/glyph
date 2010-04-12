#!/usr/bin/env ruby


macro :comment do
	""
end

macro :todo do
	todo = "[#{@source}] -- #{@value}"
	Glyph::TODOS << todo unless Glyph::TODOS.include? todo
	""
end

macro :snippet do
	begin
		ident = @params[0].to_sym
		macro_error "Snippet '#{ident}' does not exist" unless Glyph::SNIPPETS.has_key? ident
		interpret Glyph::SNIPPETS[ident] 
	rescue Exception => e
		warning e.message
		"[SNIPPET '#{@value}' NOT PROCESSED]"
	end
end

macro "snippet:" do
	ident, text = @params
	Glyph::SNIPPETS[ident.to_sym] = text
	""
end

macro :include do
	begin
		file = nil
		(Glyph::PROJECT/"text").find do |f|
			file = f if f.to_s.match /\/#{@value}$/
		end	
		macro_error "File '#{@value}' no found." unless file
		contents = file_load file
		if cfg("filters.by_file_extension") then
			begin
				ext = @value.match(/\.(.*)$/)[1]
				macro_error "Filter macro '#{ext}' not found" unless Glyph::MACROS.include?(ext.to_sym)
				contents = "#{ext}[#{contents}]"
			rescue MacroError => e
				warning e.message
			end
		end	
		interpret contents
	rescue MacroError => e
		warning e
		"[FILE '#{@value}' NOT FOUND]"
	end
end

macro :ruby do
	Kernel.instance_eval(@value)
end

macro :config do
	cfg @value
end

macro "config:" do
	setting,value = @params
	Glyph.config_override(setting, value)
	nil
end

macro :escape do
	@value
end

macro :condition do
	cond, actual_value = @params
	(interpret(cond).blank?) ? "" : actual_value
end

macro :eq do
	validate { @node.find_parent { |n| n[:macro].in? [:condition, '?'.to_sym]}}
	a, b = @params
	res_a = interpret(a.to_s) 
	res_b = interpret(b.to_s)
 	(res_a == res_b)	? true : nil
end

macro :not do
	validate { @node.find_parent { |n| n[:macro].in? [:condition, '?'.to_sym]}}
	interpret(@value).blank? ? true : nil 
end

macro :and do
	validate { @node.find_parent { |n| n[:macro].in? [:condition, '?'.to_sym]}}
	a, b = @params
	res_a = !interpret(a.to_s).blank?
	res_b = !interpret(b.to_s).blank?
	(res_a && res_b) ? true : nil
end

macro :or do
	validate { @node.find_parent { |n| n[:macro].in? [:condition, '?'.to_sym]}}
	a, b = @params
	res_a = !interpret(a.to_s).blank?
	res_b = !interpret(b.to_s).blank?
	(res_a || res_b) ? true : nil
end

macro :match do
	validate { @node.find_parent { |n| n[:macro].in? [:condition, '?'.to_sym]}}
	val, regexp = @params
	macro_error "Invalid regular expression: #{regexp}" unless regexp.match /^\/.*\/[a-z]?$/
	(interpret(val).match(instance_eval(regexp))) ? true : nil
end

macro_alias '--' => :comment
macro_alias '&' => :snippet
macro_alias '&:' => 'snippet:'
macro_alias '@' => :include
macro_alias '%' => :ruby
macro_alias '$' => :config
macro_alias '$:' => 'config:'
macro_alias '.' => :escape
macro_alias '?' => :condition
