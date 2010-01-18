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

class Hash

	def to_tree
		HashTree.new.replace self
	end

	def pair?
		self.length == 1
	end

	def name
		return nil unless self.pair?
		keys[0]
	end

	def value
		return nil unless self.pair?
		values[0]
	end

end


class HashTree < Hash

	attr_reader :children
	attr_accessor :parent

	def initialize(*args)
		super(*args)
		@children = []
	end

	def <<(hash)
		raise ArgumentError, "#{hash} is not a Hash" unless hash.is_a? Hash
		ht = (hash.is_a? HashTree) ? hash : hash.to_tree
		ht.parent = self
		@children << ht
	end

	def child(number)
		@children[number]
	end

	alias >> child 

	def each_child
		@children.each {|c| yield c }
	end

	def descend(element=nil, level=0, &block)
		element ||= self
		yield element, level
		element.each_child {|c| descend c, level+1, &block }
	end

	def ascend(element=nil, &block)
		element ||= self
		yield element
		ascend(element.parent, &block) if element.parent
	end

	def root
		ascend(parent) {|e| return e unless e.parent }
	end

end

class MacroError < RuntimeError
	attr_reader :context
	def initialize(context, msg)
		@context = context
		source = context[:source] || "--"
		super("[#{source}] #{@context[:macro].join(" > ")}: #{msg}")
	end
end
