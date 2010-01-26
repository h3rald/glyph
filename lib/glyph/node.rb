#!/usr/bin/env ruby

class Hash

	def to_node
		Glyph::Node.new.replace self
	end

end

module Glyph

	class Node < Hash

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

end
