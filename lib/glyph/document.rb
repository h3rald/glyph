#!/usr/bin/env ruby

module Glyph

	class Document

		ESCAPES = [
			['\\]', ']'], 
			['\\[', '['],
			['\\=', '='],
			['\\.', ''],
			['\\\\', '\\'],
			['\\|', '|']
		]

		def initialize(tree, context)
			raise RuntimeError, "Invalid syntax tree" unless tree.respond_to? :evaluate
			@tree = tree
			@context = context
			@bookmarks = {}
			@output = {}
			@state = :new
		end

		def bookmark(hash)
			raise RuntimeError, "Document is already #{@state}" unless scanned?
			ident = hash[:id]
			raise RuntimeError, "Bookmark '#{ident}' already exists" if @bookmarks.has_key? :ident
			@bookmarks[ident] = hash
		end

		def scan
			raise RuntimeError, "Document is already #{@state}" unless new?
			@tree.descend do |node, level|
				macro = node[:macro]
				if macro && !Glyph::MACROS.has_key?(macro)
					 warning "Scan -- Undefined macro '#{macro}'." 
				else
					Glyph::MACROS[macro].prerun self 
				end
			end
			@state = :scanned
		end

		def analyze(format)
			raise RuntimeError, "Document is #{@state}" unless scanned?
			@output[format] = @tree.evaluate @context, nil
			@state = :analyzed
		end

		def finalize(format)
			raise RuntimeError, "Document has not been analyzed" unless analyzed?
			ESCAPES.each{|e| @output[format].gsub! e[0], e[1]}
			replacements = {} 
			@tree.descend do |node, level|
				macro = node[:macro]
				obj = Glyph::MACROS[macro]
				replacements[obj.placeholder] = obj.postrun self 
			end
			replacements.each_pair {|key, value| @output[format].gsub! key, value}
			@state = :finalized
		end

		def new?
			@state == :new
		end

		def analyzed?
			@state == :analyzed
		end

		def finalized?
			@state = :finalized
		end

	end
	
end
