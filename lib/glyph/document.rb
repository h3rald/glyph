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
			@pre_actions = []
			@post_actions = {}
			@state = :new
		end

		def bookmark(hash)
			raise RuntimeError, "Document is already #{@state}" unless @state == :scanned
			ident = hash[:id]
			raise RuntimeError, "Bookmark '#{ident}' already exists" if @bookmarks.has_key? :ident
			@bookmarks[ident] = hash
		end

		def scan
			# TODO must evaluate macros to set pre/post actions!
			@pre_actions.each {|value| value.call }
			@state = :scanned
		end

		def analyze(format)
			@output[format] = @tree.evaluate @context, nil
			@state = :analyzed
		end

		def finalize(format)
			raise RuntimeError, "Document has not been analyzed" unless analyzed?
			ESCAPES.each{|e| @output[format].gsub! e[0], e[1]}
			@post_actions.each_pair {|key, value| @output[format].gsub! key.to_s, value.call.to_s}
			@state = :finalized
		end

		def pre_action(&block)
			@pre_actions << block
		end

		def post_action(key, &block)
			@post_actions[key] = block
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
