#!/usr/bin/env ruby

macro :snippet do
	no_mutual_inclusion_in 0	
	ident = value.to_sym
	if Glyph::SNIPPETS.has_key? ident then
		begin
			@node[:source] = "#{@name}[#{ident}]"
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
	ident = param(0)
	text = param(1)
	Glyph::SNIPPETS[ident.to_sym] = text
	""
end

macro "macro:" do
	exact_parameters 2
	ident = param(0)
	code = param(1)
	Glyph.macro(ident) do
		instance_eval code
	end
	""
end

macro :include do
	exact_parameters 1
	no_mutual_inclusion_in 0
	v = value
	macro_error "Macro not available when compiling a single file." if Glyph.lite?
	file = nil
	(Glyph::PROJECT/"text").find do |f|
		file = f if f.to_s.match /\/#{v}$/
	end	
	if file then
		contents = file_load file
		ext = v.match(/\.(.*)$/)[1]
		if Glyph["filters.by_file_extension"] && ext != 'glyph' then
			if Glyph::MACROS.include?(ext.to_sym) then
				contents = "#{ext}[#{contents}]"
			else
				macro_warning "Filter macro '#{ext}' not available"
			end
		end	
		begin 
			@node[:source] = "#{@name}[#{v}]"
			interpret contents
		rescue Exception => e
			raise if e.is_a? Glyph::MutualInclusionError
			macro_warning e.message, e
			macro_todo "Correct errors in file '#{value}'"
		end
	else
		macro_warning "File '#{value}' no found."
		"[FILE '#{value}' NOT FOUND]"
	end
end

macro :ruby do
	max_parameters 1
	res = Glyph.instance_eval(value.gsub(/\\*([\[\]\|])/){$1})
	res.is_a?(Proc) ? "" : res
end

macro :config do
	Glyph[value]
end

macro "config:" do
	max_parameters 2
	setting = param(0)
	v = param(1) rescue nil
	if setting.match /^system\..+/ then
		macro_warning "Cannot reset '#{setting}' setting (system use only)."
	else
		Glyph[setting] = v
	end
	nil
end

macro :comment do
	""
end

macro :escape do
	value
end

macro :condition do
	min_parameters 1
	max_parameters 2
	res = param(0)
	(res.blank? || res == "false") ? "" : param(1).to_s
end

macro :eq do
	min_parameters 1
	max_parameters 2
	(param(0).to_s == param(1).to_s)	? true : nil
end

macro :not do
	max_parameters 1
	v = param(0).to_s
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
	val = param(0).to_s
	regexp = param(1).to_s
	macro_error "Invalid regular expression: #{regexp}" unless regexp.match /^\/.*\/[a-z]?$/
	val.match(instance_eval(regexp)) ? true : nil
end

macro "alias:" do
	exact_parameters 2
	Glyph.macro_alias param(0) => param(1)
end

macro "rewrite:" do
	exact_parameters 2
	macro_name = param(0).to_sym
	raw_param(1).descend do |n, level|
		if n[:name] == macro_name then
			macro_error "Macro '#{macro_name}' cannot be defined by itself"
		end
	end
	string = raw_param(1).to_s
	Glyph.macro macro_name do
		# Parameters
		string.gsub!(/@(\d+)/) do
			raw_param($1.to_i).to_s.strip
		end
		# Attributes
		string.gsub!(/@([^\[\]\|\\\s]+)/) do
			raw_attr($1.to_sym).contents.to_s.strip
		end
		interpret string
	end
end

macro_alias '--' => :comment
macro_alias '&' => :snippet
macro_alias '&:' => 'snippet:'
macro_alias '%:' => 'macro:'
macro_alias '%' => :ruby
macro_alias '$' => :config
macro_alias '$:' => 'config:'
macro_alias '.' => :escape
macro_alias '?' => :condition
macro_alias "rw:" => :"rewrite:"
