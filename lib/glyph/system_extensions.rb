module Kernel

	# Prints a message
	# @param [#to_s] message the message to print
	def info(message)
		puts "#{message}" unless Glyph[:quiet]
	end

	# Prints a warning
	# @param [#to_s] message the message to print
	def warning(message)
		puts "warning: #{message}" unless Glyph[:quiet]
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

end

class MacroError < RuntimeError
	attr_reader :node
	def initialize(node, msg)
		@node = node
		source = @node[:source] || "--"
		macros = []
		@node.ascend {|n| macros << n[:macro].to_s if n[:macro] }
		super("#{msg}\n -> source: #{source}\n -> path: #{macros.reverse.join('/')}")
	end
end
