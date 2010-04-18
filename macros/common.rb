#!/usr/bin/env ruby

macro :snippet do
	exact_parameters 1
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
	exact_parameters 2
	ident, text = @params
	Glyph::SNIPPETS[ident.to_sym] = text
	""
end

macro :include do
	macro_error "Macro not available when compiling a single file." if Glyph.lite?
	exact_parameters 1
	begin
		file = nil
		(Glyph::PROJECT/"text").find do |f|
			file = f if f.to_s.match /\/#{@value}$/
		end	
		macro_error "File '#{@value}' no found." unless file
		contents = file_load file
		ext = @value.match(/\.(.*)$/)[1]
		if Glyph["filters.by_file_extension"] && ext != 'glyph' then
			begin
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
	exact_parameters 1
	Glyph.instance_eval(@value)
end

macro :config do
	exact_parameters 1
	Glyph[@value]
end

macro "config:" do
	exact_parameters 2
	setting,value = @params
	Glyph.config_override(setting, value)
	nil
end

macro :escape do
	exact_parameters 1
	@value
end

macro :condition do
	exact_parameters 2
	cond, actual_value = @params
	res = interpret(cond)
	(res.blank? || res == "false") ? "" : actual_value
end

macro :eq do
	min_parameters 1
	max_parameters 2
	a, b = @params
	res_a = interpret(a.to_s) 
	res_b = interpret(b.to_s)
 	(res_a == res_b)	? true : nil
end

macro :not do
	max_parameters 1
	interpret(@value).blank? ? true : nil 
end

macro :and do
	min_parameters 1
	max_parameters 2
	a, b = @params
	res_a = !interpret(a.to_s).blank?
	res_b = !interpret(b.to_s).blank?
	(res_a && res_b) ? true : nil
end

macro :or do
	min_parameters 1
	max_parameters 2
	a, b = @params
	res_a = !interpret(a.to_s).blank?
	res_b = !interpret(b.to_s).blank?
	(res_a || res_b) ? true : nil
end

macro :match do
	exact_parameters 2
	val, regexp = @params
	macro_error "Invalid regular expression: #{regexp}" unless regexp.match /^\/.*\/[a-z]?$/
	(interpret(val).match(instance_eval(regexp))) ? true : nil
end

macro_alias '&' => :snippet
macro_alias '&:' => 'snippet:'
macro_alias '@' => :include
macro_alias '%' => :ruby
macro_alias '$' => :config
macro_alias '$:' => 'config:'
macro_alias '.' => :escape
macro_alias '?' => :condition
