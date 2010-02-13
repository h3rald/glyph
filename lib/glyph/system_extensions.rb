#!/usr/bin/env ruby

module Kernel

	def info(message)
		puts "#{message}" unless Glyph::CONFIG.get :quiet
	end

	def warning(message)
		puts "warning: #{message}" unless Glyph::CONFIG.get :quiet
	end

	def cfg(setting)
		Glyph::CONFIG.get(setting)
	end

	def yaml_dump(file, obj)
		File.open(file.to_s, 'w+') {|f| f.write obj.to_yaml}
	end

	def yaml_load(file)
		YAML.load_file(file.to_s)
	end

	def file_load(file)
		result = ""
		File.open(file.to_s, 'r') do |f|
			while l = f.gets 
				result << l
			end
		end
		result
	end

	def file_write(file, contents="")
		File.open(file.to_s, 'w+') do |f|
			f.print contents
		end
		contents
	end

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
		super("[#{source} - macro: #{macros.join('/')}] #{msg}")
	end
end
