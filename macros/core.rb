#!/usr/bin/env ruby

macro :snippet do
	no_mutual_inclusion_in 0	
	ident = value.to_sym
	if Glyph::SNIPPETS.has_key? ident then
		begin
			@node[:source] = {:node => @node, :name => "snippet[#{ident}]"}
			interpret Glyph::SNIPPETS[ident] 
		rescue Exception => e
			case 
			when e.is_a?(Glyph::MutualInclusionError) then
				raise
			when e.is_a?(Glyph::MacroError) then
				Glyph.warning e.message
			else
				macro_warning e.message, e
			end
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
	safety_check
	exact_parameters 2
	ident = param(0)
	code = param(1)
	Glyph.macro(ident) do
		instance_eval code
	end
	""
end

macro :include do
	safety_check
	exact_parameters 1
	no_mutual_inclusion_in 0
	v = value
	v += ".glyph" unless v.match(/\..+$/)
	ext = v.match(/\.(.*)$/)[1] 
	if Glyph.lite? then
		file = Pathname.new(v)
	else
		if ext == 'rb' then
			file = Glyph::PROJECT/"lib/#{v}"
		else
			file = Glyph::PROJECT/"text/#{v}"
		end	
	end
	if file.exist? then
		contents = file_load file
		if ext == "rb" then
			begin
				Glyph.instance_eval contents
				""
			rescue Exception => e
				macro_warning e.message, e
			end
		else
			if Glyph["filters.by_file_extension"] && !ext.in?(['rb','glyph']) then
				if Glyph::MACROS.include?(ext.to_sym) then
					contents = "#{ext}[#{contents}]"
				else 
					macro_warning "Filter macro '#{ext}' not available"
				end
			end
			begin 
				@node[:source] = {:node => @node, :name => v}
				interpret contents
			rescue Exception => e
				case 
				when e.is_a?(Glyph::MutualInclusionError) then
					raise
				when e.is_a?(Glyph::MacroError) then
					Glyph.warning e.message
				else
					macro_warning e.message, e
				end
				macro_todo "Correct errors in file '#{value}'"
			end
		end
	else
		macro_warning "File '#{value}' no found."
		"[FILE '#{value}' NOT FOUND]"
	end
end

macro :ruby do
	safety_check
	max_parameters 1
	res = Glyph.instance_eval(value.gsub(/\\*([\[\]\|])/){$1})
	res.is_a?(Proc) ? "" : res
end

macro :config do
	Glyph[value]
end

macro "config:" do
	safety_check
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
	safety_check
	exact_parameters 2
	macro_name = param(0).to_sym
	raw_param(1).descend do |n, level|
		if n[:name] == macro_name then
			macro_error "Macro '#{macro_name}' cannot be defined by itself"
		end
	end
	string = raw_param(1).to_s
	Glyph.macro macro_name do
		s = string.dup
		# Parameters
		s.gsub!(/\{\{(\d+)\}\}/) do
			p = raw_param($1.to_i)
			p.to_s.strip
		end
		# Attributes
		s.gsub!(/\{\{([^\[\]\|\\\s]+)\}\}/) do
			a = raw_attr($1.to_sym)
			a.contents.to_s.strip rescue ""
		end
		interpret s
	end
	nil
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
macro_alias 'rw:' => 'rewrite:'
