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

		def find_child(&block)
			descend do |node, level|
				return node if block.call(node)
			end
			nil
		end

		def ascend(element=nil, &block)
			element ||= self
			yield element
			ascend(element.parent, &block) if element.parent
		end

		def root
			ascend(parent) {|e| return e unless e.parent }
		end

		### ACTIONS

		def get_params
			esc = '__[=ESCAPED_PIPE=]__'
			self[:value].gsub(/\\\|/, esc).split('|').map{|p| p.strip.gsub esc, '|'}
		end

		def store_id
			params = get_params
			ident = self[:id] || params[0].to_sym
			raise MacroError.new(self, "ID '#{ident}' already exists.") if Glyph::IDS.include? ident
			Glyph::IDS << ident
		end

		def get_snippet
			params = get_params
			ident = params[0].to_sym
			raise MacroError.new(self, "Snippet '#{ident}' does not exist.") unless Glyph::SNIPPETS.include? ident
			Glyph::SNIPPETS[ident]
		end

		def get_header
			params = get_params
			title = params[0]
			level = Glyph::CONFIG.get("structure.first_header_level") - 1
			ascend do |n| 
				if Glyph::CONFIG.get("structure.headers").include? n[:macro] then
					level+=1
				end
			end
			anchor = params[1] ? params[1] : "t_#{title.gsub(' ', '_')}_#{rand(100)}"
			self[:header] = title
			self[:id] = anchor.to_sym
			self[:level] = level
			store_id
			self
		end

		def load_file
			file = nil
			(Glyph::PROJECT/"text").find do |f|
				file = f if f.to_s.match /\/#{self[:value]}$/
			end	
			raise ArgumentError, "File #{self[:value]} no found." unless file
			file_load file
		end

	end

end
