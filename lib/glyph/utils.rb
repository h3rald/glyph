# encoding: utf-8

module Glyph
	#@since 0.4.0
	module Utils

		# Prints a message
		# @param [String] message the message to print
		def msg(message)
			puts message unless Glyph['system.quiet']
		end

		# Prints an informational message
		# @param [String] message the message to print
		def info(message)
			puts "-- #{message}" unless Glyph['system.quiet']
		end

		# Prints a warning
		# @param [String] message the message to print
		def warning(message)
			puts "-> warning: #{message}" unless Glyph['system.quiet']
		end

		# Prints an error
		# @param [String] message the message to print
		def error(message)
			puts "=> error: #{message}" unless Glyph['system.quiet']
		end

		# Prints a message if running in debug mode
		# @param [String] message the message to print
		def debug(message)
			puts message if Glyph.debug?
		end

		# Dumps and serialize an object to a YAML file
		# @param [#to_s] file the file to write to
		# @param [Object] obj the object to serialize
		def yaml_dump(file, obj)
			File.open(file.to_s, 'w+') {|f| f.write obj.to_yaml}
		end

		# Loads and deserialiaze the contents of a YAML file
		# @param [#to_s] file the YAML file to load
		# @return [Object] the contents of the YAML file, deserialized
		def yaml_load(file)
			YAML.load_file(file.to_s)
		end

		# Loads the contents of a file
		# @param [#to_s] file the file to load
		# @return [String] the contents of the file
		def file_load(file)
			result = ""
			File.open(file.to_s, 'r') do |f|
				while l = f.gets 
					result << l
				end
			end
			result
		end

		# Writes a string to a file
		# @param [#to_s] file the file to write
		# @param [String] contents the string to write
		# @return [String] the string written to the file
		def file_write(file, contents="")
			File.open(file.to_s, 'w+') do |f|
				f.print contents
			end
			contents
		end

		# An alias for FileUtils#cp
		# @param [String] source the source file
		# @param [String] dest the destination file or directory
		# @param [Hash] options copy options
		def file_copy(source, dest, options={})
			FileUtils.cp source, dest, options
		end

		# Loads all child elements of the given directory, matching a given extension
		# @param [Pathname] dir the directory containing the files
		# @param [String] extension the file extension to check
		# @yield [file, contents] the file (Pathname) and its contents
		# @since 0.4.0
		def load_files_from_dir(dir, extension, &block)
			if dir.exist? then
				dir.children.each do |c|
					block.call(c, file_load(c)) unless c.directory? || c.extname != extension
				end
			end
		end

		# Iterates through the files in a source directory recursively
		# @param [String] dir the directory to operate on (mirrored in the output directory)
                # @yield [src, dest] the source file and the corresponding output file
		# @since 0.4.0
		def with_files_from(dir, &block)
			output = (Glyph['document.output'] == 'pdf') ? 'html' : Glyph['document.output']
			dir_path = Glyph::PROJECT/"output/#{output}/#{dir}"
			dir_path.mkpath
			(Glyph::PROJECT/dir).find do |i|
				if i.file? then
					dest = "#{Glyph::PROJECT/"output/#{output}/#{dir}"}/#{i.relative_path_from(Glyph::PROJECT/dir)}"
					src = i.to_s
					Pathname.new(dest).parent.mkpath
					block.call src, dest
				end
			end
		end

		# Returns true if the macro name is used as an alias
		# @param [String, Symbol] name the macro name to check
		def macro_alias?(name)
			ALIASES[:by_alias].include? name.to_sym
		end

		# Returns the name of the macro definition referenced by the supplied alias
		# @param [String, Symbol] name the alias name to check
		def macro_definition_for(name)
			ALIASES[:by_alias][name.to_sym]
		end

		# Returns the names of the macro aliases referencing the supplied definition
		# @param [String, Symbol] name the macro name to check
		def macro_aliases_for(name)
			ALIASES[:by_def][name.to_sym]
		end

		# Returns a list of macro names corresponding to sections
		# that commonly have a title
		def titled_sections
			(Glyph['system.structure.frontmatter']+
			Glyph['system.structure.bodymatter']+
			Glyph['system.structure.backmatter']+
			[:section]).uniq
		end

		# Returns true if the macro names point to the same definition
		# @param [String, Symbol] ident1 the first macro to compare
		# @param [String, Symbol] ident2 the second macro to compare
		def macro_eq?(ident1, ident2)
			Glyph::MACROS[ident1.to_sym] == Glyph::MACROS[ident2.to_sym]
		end

		# Returns true if the PROJECT constant is set to a valid Glyph project directory
		def project?
			children = ["text", "snippets.yml", "config.yml", "document.glyph"].sort
			actual_children = PROJECT.children.map{|c| c.basename.to_s}.sort 
			(actual_children & children) == children
		end

		# Returns true if multiple output files are being generated
		def multiple_output_files?
			Glyph["output.#{Glyph['document.output']}.multifile"]
		end

	end
end
