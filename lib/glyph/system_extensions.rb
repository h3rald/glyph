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

	def file_write(file, contents="")
		File.open(file, 'w+') do |f|
			f.write contents
		end
	end

	def file_copy(source, dest, options={})
		FileUtils.cp source, dest, options
	end

end

class Hash

	def to_node
		HashNode.new.replace self
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


class HashNode < Hash

	attr_reader :children
	attr_accessor :parent

	def initialize(*args)
		super(*args)
		@children = []
	end

	def to_node
		self
	end

	def from(node)
		n = node.to_node
		replace node
		@parent = n.parent
		@children = n.children
	end

	def <<(hash)
		raise ArgumentError, "#{hash} is not a Hash" unless hash.is_a? Hash
		ht = hash.to_node
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
		element.each_child do |c| 
			descend c, level+1, &block 
		end
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
	attr_reader :node
	def initialize(node, msg)
		@node = node
		source = @node[:source] || "--"
		macros = []
		@node.ascend {|n| macros << n[:macro] if n[:macro] }
		macros.join(" > ")
		super("[#{source}] #{macros}: #{msg}")
	end
end
