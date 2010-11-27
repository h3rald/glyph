# encoding: utf-8

class Hash

	# Converts self to a Node
	# @return [Node] the converted Node
	def to_node
		Node.new.replace self
	end

end


# A Node is a Hash with an array of children and a parent associated to it.
class Node < Hash

	attr_reader :children
	attr_accessor :parent

	# Creates a new Node
	def initialize(*args)
		super(*args)
		@children = []
	end

	# @return [Node] Returns self
	def to_node
		self
	end

	# Clone another node (replaces all keys, parent and children)
	# @param [#to_node] node the Node to clone
	# @return [self]
	def from(node)
		n = node.to_node
		replace node
		@parent = n.parent
		@children = n.children
		self
	end

	# Clears all keys, parent and children
	def clear
		super
		@children.clear
		@parent = nil
	end

	# Adds a child node to self
	# @param [Hash] hash the new child
	# @return [Array] the node's children
	# @raise [ArgumentError] unless a Hash is passed as parameter
	def <<(hash)
		raise ArgumentError, "#{hash} is not a Hash" unless hash.is_a? Hash
		ht = hash.to_node
		ht.parent = self
		@children << ht
	end

	# Removes a child node from self
	# @param [node] node the child node to remove
	# @raise [ArgumentError] unless an existing child node is passed as parameter
	def >>(node)
		raise ArgumentError, "Unknown child node" unless @children.include? node
		node.parent = nil
		@children.delete node
	end

	# Returns a child by its index
	# @return [Node] the child node or nil
	# @param [Integer] index the child index
	def child(index)
		@children[index]
	end

	# See Node#child.
	def &(index)
	 	@children[index]
	end	

	# Iterates through children
	# @yieldparam [Node] c the child node
	def each_child
		@children.each {|c| yield c }
	end


	# Iterates through children recursively (including self)
	# @param [Node, nil] element the node to process
	# @yieldparam [Node] element the current node
	# @yieldparam [Integer] level the current tree depth
	def descend(element=nil, level=0, &block)
		element ||= self
		yield element, level
		element.each_child do |c| 
			descend c, level+1, &block 
		end
	end

	# Descend children until the block returns something. 
	# 	Each child is passed to the block.
	# @param [Proc] &block the block to call on each child
	# @return [Node, nil] returns the child node if found, nil otherwise
	def find_child(&block)
		children.each do |c|
			c.descend do |node, level|
				return node if block.call(node)
			end
		end
		nil
	end

	# Ascend parents until the block returns something. 
	# 	Each parent is passed to the block.
	# @param [Proc] &block the block to call on each parent
	# @return [Node, nil] returns the parent node if found, nil otherwise
	def find_parent(&block)
		return nil unless parent
		parent.ascend do |node|
			return node if block.call(node)
		end
		nil
	end

	# Iterates through parents recursively (including self)
	# @param [Node, nil] element the node to process
	# @yieldparam [Node] element the current node
	def ascend(element=nil, &block)
		element ||= self
		yield element
		ascend(element.parent, &block) if element.parent
	end

	# @return [Node] Returns the root node
	def root
		ascend(parent) {|e| return e unless e.parent }
	end

	# Converts self to a hash
	# @return [Hash] the converted hash
	# @since 0.3.0
	def to_hash
		{}.merge(self)
	end

	# @return [String] a textual representation of self
	# @since 0.3.0
	def inspect
		string = ""
		descend do |e, level|
			string << "  "*level+e.to_hash.inspect+"\n"
		end
		string.chomp
	end
	
	# @return (Boolean) true if the nodes are equal
	# @since 0.3.0
	def ==(node)
		return false unless node.is_a? Node
	 	self.to_hash == node.to_hash && self.children == node.children
	end

end
