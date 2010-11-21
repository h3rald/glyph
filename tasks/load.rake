#!/usr/bin/env ruby

namespace :load do
	include Glyph::Utils

	desc "Load all files"
	task :all => [:config, :tasks, :commands, :snippets, :macros] do
	end

	desc "Load tasks"
	task :tasks do
		unless Glyph.lite? then
			load_files_from_dir(Glyph::PROJECT/'lib/tasks', '.rake') do |f, contents|
				load f
			end	
		end
	end

	desc "Load commands"
	task :commands do
		unless Glyph.lite? then
			include GLI if (Glyph::PROJECT/'lib/commands').exist?
			load_files_from_dir(Glyph::PROJECT/'lib/commands', '.rb') do |f, contents|
				require f
			end
		end
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
			load_files_from_dir(dir, ".rb") do |file, contents|
				Glyph.instance_eval contents
			end
		end
		load_layouts_from_dir = lambda do |dir|
			load_files_from_dir(dir, ".glyph") do |file, contents|
				Glyph.rewrite "layout:#{file.basename(file.extname)}".to_sym, contents
			end
		end
		case  Glyph['options.macro_set']
		when 'glyph' then
			load_macros_from_dir.call Glyph::HOME/"macros"
			# Load representations
			Glyph.instance_eval file_load(Glyph::HOME/"macros/reps/#{Glyph['document.output']}.rb")
			layout_dirs = Glyph["output.#{Glyph['document.output']}.layout_dirs"] || []
			layout_dirs.each {|d| load_layouts_from_dir.call Glyph::HOME/"layouts/#{d}" }
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
			Glyph.instance_eval file_load(Glyph::PROJECT/"lib/macros/reps/#{Glyph['document.output']}.rb") rescue nil
			load_layouts_from_dir.call Glyph::PROJECT/'lib/layouts' if Glyph.multiple_output_files?
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
