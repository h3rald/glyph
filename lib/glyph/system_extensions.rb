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

end
