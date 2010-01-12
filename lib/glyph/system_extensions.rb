#!/usr/bin/env ruby

module Kernel

	def info(message)
		puts " ->  #{message}" unless Glyph::CONFIG.get :quiet
	end

	def warning(message)
		puts " [!] #{message}" unless Glyph::CONFIG.get :quiet
	end

	def yaml_dump(file, obj)
		File.open(file.to_s, 'w+') {|f| f.write obj.to_yaml}
	end

	def yaml_load(file)
		YAML.load_file(file.to_s)
	end

	def file_load(file)
		result = ""
		File.open(file, 'r') do |f|
			while l = f.gets 
				result << l
			end
		end
		result
	end

	def file_copy(source, dest, options={})
		FileUtils.cp source, dest, options
	end

end
