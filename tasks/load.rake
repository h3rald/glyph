#!/usr/bin/env ruby

namespace :load do

	desc "Load all files"
	task :all => [:snippets, :macros] do
	end
	
	desc "Load snippets"
	task :snippets do
		snippets = yaml_load Glyph::PROJECT/'snippets.yml'
		raise RuntimeError, "Invalid snippets file" unless snippets.blank? || snippets.is_a?(Hash)
		Glyph::SNIPPETS.replace snippets
	end

	desc "Load macros"
	task :macros do
		macro_base = Glyph::PROJECT/"lib/macros"
		Glyph::Interpreter.instance_eval(file_load macro_base/"filters.rb")
		macro_dir = macro_base/Glyph::CONFIG.get("filters.target").to_s
		if macro_dir.exist? then
			macro_dir.children.each do |f|
				Glyph::Interpreter.instance_eval(file_load f)
			end
		end
	end

end
