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
		macro_error "Snippet '#{ident}' does not exist" unless Glyph::SNIPPETS.include? ident
		interpret Glyph::SNIPPETS[ident]
	rescue Exception => e
		warning e.message
		"[SNIPPET '#{@value}' NOT FOUND]"
	end
end

macro :include do
	begin
		file = nil
		(Glyph::PROJECT/"text").find do |f|
			file = f if f.to_s.match /\/#{@value}$/
		end	
		macro_error "File #{@value} no found." unless file
		contents = file_load file
		if cfg("filters.by_file_extension") then
			begin
				ext = @value.match(/\.(.*)$/)[1]
				macro_error "Macro '#{ext}' not found" unless Glyph::MACROS.include?(ext.to_sym)
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

macro :escape do
	@value 
end

macro :ruby do
	Kernel.instance_eval(@value)
end

macro :config do
	cfg @value
end

macro_alias '--' => :comment
macro_alias '&' => :snippet
macro_alias '.' => :escape
macro_alias '@' => :include
macro_alias '%' => :ruby
macro_alias '$' => :config
