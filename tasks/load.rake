#!/usr/bin/env ruby

namespace :load do
	include Glyph::Utils

	desc "Load all files"
	task :all => [:config, :snippets, :macros] do
	end

	desc "Load snippets"
	task :snippets do
		unless Glyph.lite? then
			raise RuntimeError, "The current directory is not a valid Glyph project" unless Glyph.project?
			snippets = yaml_load Glyph::PROJECT/'snippets.yml'
			raise RuntimeError, "Invalid snippets file" unless snippets.blank? || snippets.is_a?(Hash)
			Glyph::SNIPPETS.replace snippets
		end
	end

	desc "Load macros"
	task :macros do
		raise RuntimeError, "The current directory is not a valid Glyph project" unless Glyph.project? || Glyph.lite?
		load_macros_from_dir = lambda do |dir|
			if dir.exist? then
				dir.children.each do |c|
					Glyph.instance_eval file_load(c) unless c.directory? || c.extname != '.rb'
				end
			end
		end
		case  Glyph['language.set']
		when 'glyph' then
			Glyph.instance_eval file_load(Glyph::HOME/'macros/core.rb')
			Glyph.instance_eval file_load(Glyph::HOME/'macros/filters.rb')
			Glyph.instance_eval file_load(Glyph::HOME/'macros/xml.rb')
			case Glyph['document.output']
			when 'pdf'
				load_macros_from_dir.call Glyph::HOME/"macros/html"
			when 'html'
				load_macros_from_dir.call Glyph::HOME/"macros/html"
			when 'web'
				load_macros_from_dir.call Glyph::HOME/"macros/html"
				load_macros_from_dir.call Glyph::HOME/"macros/web"
			when 'html5'
				load_macros_from_dir.call Glyph::HOME/"macros/html5"
			when 'web5'
				load_macros_from_dir.call Glyph::HOME/"macros/html5"
				load_macros_from_dir.call Glyph::HOME/"macros/web"
				load_macros_from_dir.call Glyph::HOME/"macros/web5"
			else
				warning "No #{Glyph['document.output']} macros defined"
			end
		when 'xml' then
			Glyph.instance_eval file_load(Glyph::HOME/'macros/core.rb') 
			Glyph.instance_eval file_load(Glyph::HOME/'macros/filters.rb') 
			Glyph.instance_eval file_load(Glyph::HOME/'macros/xml.rb') 
		when 'filters' then
			Glyph.instance_eval file_load(Glyph::HOME/'macros/core.rb') 
			Glyph.instance_eval file_load(Glyph::HOME/'macros/filters.rb') 
		when 'core' then
			Glyph.instance_eval file_load(Glyph::HOME/'macros/core.rb') 
		end
		# load project macros
		unless Glyph.lite? then
			load_macros_from_dir.call Glyph::PROJECT/"lib/macros"
		end
	end

	desc "Load configuration files"
	task :config do
		raise RuntimeError, "The current directory is not a valid Glyph project" unless Glyph.project? || Glyph.lite?
		# Save overrides set by commands...
		overrides = Glyph::PROJECT_CONFIG.dup
		Glyph::PROJECT_CONFIG.read unless Glyph.lite?
		Glyph::PROJECT_CONFIG.merge! overrides
		Glyph::SYSTEM_CONFIG.read
		Glyph::GLOBAL_CONFIG.read
        Glyph.config_refresh
		Glyph["system.structure.headers"] = [:section] +
													Glyph['system.structure.frontmatter'] + 
													Glyph['system.structure.backmatter'] + 
													Glyph['system.structure.bodymatter'] - 
													Glyph['system.structure.hidden']
	end

end
