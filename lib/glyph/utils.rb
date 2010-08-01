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

		def load_files_from_dir(dir, extension, &block)
			if dir.exist? then
				dir.children.each do |c|
					block.call(c, file_load(c)) unless c.directory? || c.extname != extension
				end
			end
		end

	end
end
