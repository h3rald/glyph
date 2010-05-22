#!/usr/bin/env ruby

macro :snippet do
	ident = value.strip.to_sym
	if Glyph::SNIPPETS.has_key? ident then
		begin
			interpret Glyph::SNIPPETS[ident] 
		rescue Exception => e
			raise if e.is_a? Glyph::MutualInclusionError
			macro_warning e.message, e
			macro_todo "Correct errors in snippet '#{ident}'"
		end
	else
		macro_warning "Snippet '#{ident}' does not exist"
		"[SNIPPET '#{ident}' NOT PROCESSED]"
	end
end

macro "snippet:" do
	exact_parameters 2
	ident, text = params
	Glyph::SNIPPETS[ident.to_sym] = text
	""
end

macro "macro:" do
	exact_parameters 2
	ident, code = params
	Glyph.macro(ident) do
		instance_eval code
	end
	""
end

macro :include do
	macro_error "Macro not available when compiling a single file." if Glyph.lite?
	file = nil
	(Glyph::PROJECT/"text").find do |f|
		file = f if f.to_s.match /\/#{raw_value}$/
	end	
	if file then
		contents = file_load file
		ext = raw_value.match(/\.(.*)$/)[1]
		if Glyph["filters.by_file_extension"] && ext != 'glyph' then
			if Glyph::MACROS.include?(ext.to_sym) then
				contents = "#{ext}[#{contents}]"
			else
				macro_warning "Filter macro '#{ext}' not available"
			end
		end	
		begin 
			interpret contents
		rescue Exception => e
			raise if e.is_a? Glyph::MutualInclusionError
			macro_warning e.message, e
			macro_todo "Correct errors in file '#{raw_value}'"
		end
	else
		macro_warning "File '#{raw_value}' no found."
		"[FILE '#{raw_value}' NOT FOUND]"
	end
end

macro :ruby do
	res = Glyph.instance_eval(raw_value.gsub(/\\*([\[\]\|])/){$1})
	res.is_a?(Proc) ? "" : res
end

macro :config do
	if raw_value.match /^system\..+/ then
		macro_warning "Cannot reset '#{raw_value}' setting (system use only)."
	else
		Glyph[raw_value]
	end
end

macro "config:" do
	exact_parameters 2
	setting,value = params
	Glyph[setting] = value
	nil
end

macro :comment do
	""
end

macro :escape do
	raw_value
end

macro :encode do
	encode raw_value
end

macro :decode do
	decode raw_value
end

macro :condition do
	min_parameters 1
	max_parameters 2
	cond, actual_value = params
	res = interpret(cond)
	if res.blank? || res == "false" then
	 	"" 
	else
		interpret(decode(actual_value))
	end
end


macro :eq do
	min_parameters 1
	max_parameters 2
	a, b = params
	res_a = interpret(a.to_s) 
	res_b = interpret(b.to_s)
	(res_a == res_b)	? true : nil
end

macro :not do
	max_parameters 1
	v = interpret(raw_value)
	(v.blank? || v == "false") ? true : nil 
end

macro :and do
	min_parameters 1
	max_parameters 2
	a, b = params
	res_a = !interpret(a.to_s).blank?
	res_b = !interpret(b.to_s).blank?
	(res_a && res_b) ? true : nil
end

macro :or do
	min_parameters 1
	max_parameters 2
	a, b = params
	res_a = !interpret(a.to_s).blank?
	res_b = !interpret(b.to_s).blank?
	(res_a || res_b) ? true : nil
end

macro :match do
	exact_parameters 2
	val, regexp = params
	macro_error "Invalid regular expression: #{regexp}" unless regexp.match /^\/.*\/[a-z]?$/
	(interpret(val).match(instance_eval(regexp))) ? true : nil
end

macro "|param|" do
	@node.parent[:params][@node[:element]] = { 
		:name => @node[:element], 
		:value => raw_value,
		:order => @node.parent[:params].keys.length
	}
	nil
end

macro_alias '--' => :comment
macro_alias '*' => :encode
macro_alias '**' => :decode
macro_alias '&' => :snippet
macro_alias '&:' => 'snippet:'
macro_alias '%:' => 'macro:'
macro_alias '@' => :include
macro_alias '%' => :ruby
macro_alias '$' => :config
macro_alias '$:' => 'config:'
macro_alias '.' => :escape
macro_alias '?' => :condition
