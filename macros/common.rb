#!/usr/bin/env ruby

macro :snippet do
	no_mutual_inclusion_in 0	
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
		file = f if f.to_s.match /\/#{value.strip}$/
	end	
	if file then
		contents = file_load file
		ext = value.strip.match(/\.(.*)$/)[1]
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
			macro_todo "Correct errors in file '#{value.strip}'"
		end
	else
		macro_warning "File '#{value.strip}' no found."
		"[FILE '#{value.strip}' NOT FOUND]"
	end
end

macro :ruby do
	res = Glyph.instance_eval(value.gsub(/\\*([\[\]\|])/){$1})
	res.is_a?(Proc) ? "" : res
end

macro :config do
	if value.strip.match /^system\..+/ then
		macro_warning "Cannot reset '#{value.strip}' setting (system use only)."
	else
		Glyph[value.strip]
	end
end

macro "config:" do
	exact_parameters 2
	setting, val = params
	Glyph[setting.strip] = val.strip
	nil
end

macro :comment do
	""
end

macro :escape do
	value.strip
end

=begin
macro :encode do
	encode raw_value
end

macro :decode do
	decode raw_value
end
=end

macro :condition do
	min_parameters 1
	max_parameters 2
	res = param(0)
	(res.blank? || res == "false") ? "" : param(1)
end


macro :eq do
	min_parameters 1
	max_parameters 2
	(param(0) == param(1))	? true : nil
end

macro :not do
	max_parameters 1
	v = param(0)
	(v.blank? || v == "false") ? true : nil 
end

macro :and do
	min_parameters 1
	max_parameters 2
	res_a = !param(0).blank?
	res_b = !param(1).blank?
	(res_a && res_b) ? true : nil
end

macro :or do
	min_parameters 1
	max_parameters 2
	res_a = !param(0).blank?
	res_b = !param(1).blank?
	(res_a || res_b) ? true : nil
end

macro :match do
	exact_parameters 2
	val = param(0).strip
	regexp = param(1).strip
	macro_error "Invalid regular expression: #{regexp}" unless regexp.match /^\/.*\/[a-z]?$/
	val.match(instance_eval(regexp)) ? true : nil
end

macro_alias '--' => :comment
macro_alias '*' => :encode
macro_alias '**' => :decode
macro_alias '&' => :snippet
macro_alias '&:' => 'snippet:'
macro_alias '%:' => 'macro:'
macro_alias '%' => :ruby
macro_alias '$' => :config
macro_alias '$:' => 'config:'
macro_alias '.' => :escape
macro_alias '?' => :condition
