#!/usr/bin/env ruby
# encoding: utf-8

macro :snippet do
	ident = value.to_sym
	if snippet? ident then
		begin
			update_source "snippet[#{ident}]"
			interpret snippet?(ident) 
		rescue Exception => e
			case 
			when e.is_a?(Glyph::MutualInclusionError) then
				raise
			when e.is_a?(Glyph::MacroError) then
				macro_warning e.message, e
			else
				macro_warning e.message, e
			end
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
	snippet ident, text
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

macro :load do
	safety_check
	exact_parameters 1
	file = param 0 
	path = Glyph::PROJECT/file
	if path.exist? then
		file_load path
	else
		macro_warning "File '#{file}' no found."
		"[FILE '#{value}' NOT FOUND]"
	end
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
			if Glyph["options.filter_by_file_extension"] && !ext.in?(['rb','glyph']) then
				if Glyph::MACROS.include?(ext.to_sym) then
					contents = "#{ext}[#{contents}]"
				else 
					macro_warning "Filter macro '#{ext}' not available"
				end
			end
			begin 
				folder = Glyph.lite? ? "" : "text/" 
				topic = (attr(:topic) && Glyph.multiple_output_files?) ? folder+v : nil
				update_source v, folder+v, topic
				interpret contents
			rescue Glyph::MutualInclusionError => e
				raise
			rescue Glyph::MacroError => e
				macro_warning e.message, e
			rescue Exception => e
				macro_warning e.message, e
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
	max_parameters 3
	res = param(0)
	(res.blank? || res == "false") ? param(2).to_s : param(1).to_s
end

macro :eq do
	exact_parameters 2
	(param(0) == param(1))	? true : nil
end

macro :not do
	max_parameters 1
	v = param(0).to_s
	(v.blank? || v == "false") ? true : nil 
end

macro :and do
	exact_parameters 2
	res_a = !param(0).blank?
	res_b = !param(1).blank?
	(res_a && res_b) ? true : nil
end

macro :or do
	exact_parameters 2
	res_a = !param(0).blank?
	res_b = !param(1).blank?
	(res_a || res_b) ? true : nil
end

macro :lt do
	exact_parameters 2
	(param(0) < param(1)) ? true : nil
end

macro :lte do
	exact_parameters 2
	(param(0) <= param(1)) ? true : nil
end

macro :gt do
	exact_parameters 2
	(param(0) > param(1)) ? true : nil
end

macro :gte do
	exact_parameters 2
	(param(0) >= param(1)) ? true : nil
end

macro "alias:" do
	exact_parameters 2
	Glyph.macro_alias param(0) => param(1)
end

macro "define:" do
	safety_check
	exact_parameters 2
	Glyph.define param(0).to_sym, raw_param(1).dup	
	nil
end

macro "output?" do
	Glyph['document.output'].in? parameters
end

macro :layout do
	dispatch do |node|
		node[:name] = "layout/#{node[:name]}".to_sym
		Glyph::Macro.new(node).expand
	end
end

macro :let do
	exact_parameters 1
	param(0).to_s
end

macro :attribute do
	exact_parameters 1
	a = param(0).to_sym
	macro_node = @node.find_parent do |n|
		n.is_a?(Glyph::MacroNode) && n.attr(a)
	end
	if macro_node then
		Glyph::Macro.new(macro_node).attr(a)
	else
		nil
	end
end

macro "attribute:" do
	exact_parameters 2
	a = param(0).to_sym
	macro_node = @node.find_parent do |n|
		n.is_a?(Glyph::MacroNode) && n.attr(a)
	end
	macro_error "Undeclared attribute '#{a}'" unless macro_node
	attr_value = param(1)
	macro_node.attr(a).children.clear
	macro_node.attr(a) << Glyph::TextNode.new.from(:value => attr_value)	
	nil
end

macro :add do
	min_parameters 2
	params.inject(0){|sum, n| sum + n.to_i}
end

macro :subtract do
	min_parameters 2
	params[1..params.length-1].inject(params[0].to_i){|diff, n| diff - n.to_i}
end

macro :multiply do
	min_parameters 2
	params.inject(1){|mult, n| mult * n.to_i}
end

macro :s do
	dispatch do |node|
		forbidden = [:each, :each_line, :each_byte, :upto, :intern, :to_sym, :to_f]
		meth = node[:name]
		infer_type = lambda do |str|
			case
			when str.match(/[+-]?\d+/) then
				# Integer
				str.to_i
			when str.match(/^\/.+?\/[imoxneus]?$/) then
				# Regexp
				Kernel.instance_eval str
			else
				str
			end
		end
		macro_error "Macro 's/#{meth}' takes at least one parameter" unless node.params.length > 0
		macro_error "String method '#{meth}' is not supported" if meth.in?(forbidden) || meth.to_s.match(/\!$/)
		str = node.param(0).evaluate(node, :params => true)
		begin
			if node.param(1) then
				meth_params = node.params[1..node.params.length-1].map{|p| infer_type.call(p.evaluate(node, :params => true))}
				str.send(meth, *meth_params).to_s
			else
				str.send(meth).to_s
			end
		rescue Exception => e
			macro_warning "\"#{str}\".#{meth}(#{meth_params.map{|p| p.inspect}.join(', ') rescue nil}) - #{e.message}", e
			""
		end
	end
end

macro :while do
	exact_parameters 2
	raw_cond = @node.parameter 0
	raw_body = @node.parameter 1
	cond = raw_cond.evaluate(@node, :params => true)
	while (!cond.blank? && cond != "false") do
		result = raw_body.evaluate(@node, :params => true)
		cond = raw_cond.evaluate(@node, :params => true)
		result
	end
end

macro :fragment do
	exact_parameters 2
	ident, contents = param(0).to_sym, param(1)
	macro_error "Fragment '#{ident}' is already defined" if @node[:document].fragments.has_key? ident
	@node[:document].fragments[ident] = contents
end

macro :embed do
	exact_parameters 1
	ident = param(0).to_sym
	placeholder do |document|
		fragment = document.fragments[ident]
		macro_error "Fragment '#{ident}' is not defined" unless fragment
		fragment
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
macro_alias 'def:' => 'define:'
macro_alias '@' => :attribute
macro_alias :attr => :attribute
macro_alias '@:' => "attribute:"
macro_alias "attr:" => "attribute:"
macro_alias "##" => :fragment
macro_alias "<=" => :embed
