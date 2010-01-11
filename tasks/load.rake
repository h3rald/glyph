#!/usr/bin/env ruby

namespace :load do

	desc "Load snippets"
	task :snippets do
		snippets = yaml_load Glyph::PROJECT/'snippets.yml'
		raise RuntimeError, "Invalid snippets file" unless snippets.blank? || snippets.is_a?(Hash)
		Glyph::SNIPPETS.replace snippets
	end

	desc "Load macros"
	task :macros do
		Glyph::Preprocessor.instance_eval file_load(Glyph::PROJECT/'lib/macros.rb')
	end

end
