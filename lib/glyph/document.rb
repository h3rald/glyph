# encoding: utf-8

module Glyph

	# The Glyph::Document class stores information about a document or a chunk of text
	# currently being interpreted.
	#
	# It is responsible of analyzing (evaluating) the syntax tree and return the corresponding output
	# as well as replacing placeholders.
	class Document

		ESCAPES = /\\([\\\]\[\|.=])/

		attr_reader :bookmarks, :placeholders, :headers, :styles, :context, :errors, :todos, :topics, :links, :toc, :fragments

		# Creates a new document
		# @param [GlyphSyntaxNode] tree the syntax tree to be evaluate
		# @param [Glyph::Node] context the context associated with the tree
		# @raise [RuntimeError] unless tree responds to :evaluate
		def initialize(tree, context={})
			@tree = tree
			@context = context
			@context[:source] ||= {:file => nil, :name => '--', :topic => nil}
			@placeholders = {}
			@bookmarks = {}
			@headers = {}
			@fragments = {}
			@styles = []
			@errors = []
			@todos = []
			@topics = []
			@links = []
			@toc = {}
			@state = :new
		end

		# Returns a tree of Glyph::Node objects corresponding to the analyzed document
		# @raise [RuntimeError] unless the document has been analized
		def structure
			raise RuntimeError, "Document has not been analyzed" unless analyzed? || finalized?
			@tree
		end

		# Copies bookmarks, headers, todos, styles and placeholders from another Glyph::Document
		# @param [Glyph::Document] document a valid Glyph::Document
		# @param [Hash] data specifies which data will be inherited (e.g. bookmarks, headers, ...).
		# 	By default, all data is inherited.
		# @example Inheriting everything except topics
		# 	doc1.inherit_from doc2, :topics => false 
		def inherit_from(document, data={})
			@bookmarks = document.bookmarks unless data[:bookmarks] == false
			@headers = document.headers unless data[:headers] == false
			@todos = document.todos unless data[:todos] == false
			@styles = document.styles unless data[:styles] == false
			@topics = document.topics unless data[:topics] == false
			@placeholders = document.placeholders unless data[:placeholders] == false
			@toc = document.toc unless data[:toc] == false
			@links = document.links unless data[:links] == false
			@fragments = document.fragments unless data[:fragments] == false
			self
		end

		# Defines a placeholder block that will be evaluated after the whole document has been analyzed
		# @param [Proc] &block a block taking the document itself as parameter
		# @return [String] the placeholder key string
		def placeholder(&block)
			key = "‡‡‡‡‡PLACEHOLDER¤#{@placeholders.length+1}‡‡‡‡‡".to_sym
			@placeholders[key] = block
			key
		end

		# Returns a stored bookmark or nil
		# @param [#to_sym] key the bookmark identifier
		# @return [Glyph::Bookmark, nil] the bookmark or nil if no bookmark is found
		def bookmark?(key)
			@bookmarks[key.to_sym]
		end

		# Stores a new bookmark
		# @param [Hash] hash the bookmark hash: {:id => "BookmarkID", :title => "Bookmark Title", :file => "dir/preface.glyph"}
		# @return [Glyph::Bookmark] the stored bookmark
		# @raise [RuntimeError] if the bookmark is already defined.
		def bookmark(hash)
			b = Glyph::Bookmark.new(hash)
			raise RuntimeError, "Bookmark '#{b.code}' already exists" if @bookmarks.has_key? b.code
			@bookmarks[b.code] = b
			b
		end

		# Stores a new header
		# @param [Hash] hash the header hash: {:id => "Bookmark_ID", :title => "Bookmark Title", :level => 3}
		# @return [Glyph::Header] the stored header
		# @raise [RuntimeError] if the bookmark is already defined.
		def header(hash)
			b = Glyph::Header.new(hash)
			raise RuntimeError, "Bookmark '#{b.code}' already exists" if @bookmarks.has_key? b.code
			@bookmarks[b.code] = b
			@headers[b.code] = b
			b
		end

		# Returns a stored header or nil
		# @param [String, Symbol] key the header identifier
		# @return [Glyph::Header, nil] the header or nil if no header is found
		def header?(key)
			@headers[key.to_sym]
		end

		# @since 0.4.0
		# Stores a stylesheet
		# @param [String] file the stylesheet file
		# @raises [RuntimeError] if the stylesheet is already specified for the document (unless the output has more than one file)
		def style(file)
			f = Pathname.new file
			if @styles.include?(f) && !Glyph.multiple_output_files? then
				raise RuntimeError, "Stylesheet '#{f}' already specified for the current document" 
			end
			@styles << f
		end

		# Analyzes the document by evaluating its @tree
		# @return [:analyzed]
		# @raise [RuntimeError] if the document is already analyzed or finalized
		def analyze
			raise RuntimeError, "Document is #{@state}" if analyzed? || finalized?
			@context[:document] = self
			@output = @tree.evaluate @context
			@state = :analyzed
		end

		# Finalizes the document by evaluating its @placeholders
		# @return [:finalized]
		# @raise [RuntimeError] if the document the document has not been analyzed,
		# 	if it is already finalized or if errors occurred during analysis
		def finalize
			raise RuntimeError, "Document has not been analyzed" unless analyzed?
			raise RuntimeError, "Document has already been finalized" if finalized?
			return (@state = :finalized) if @context[:embedded]
			raise RuntimeError, "Document cannot be finalized due to previous errors" unless @context[:document].errors.blank?
			# Substitute placeholders
			@placeholders.each_pair do |key, value| 
				begin
					key_s = key.to_s
					value_s = value.call(self).to_s
					toc[:contents].gsub! key_s, value_s rescue nil
					@topics.each do |t|
						t[:contents].gsub! key_s, value_s
					end
					@output.gsub! key_s, value_s
				rescue Glyph::MacroError => e
					e.macro.macro_warning e.message, e
				rescue Exception => e
					Glyph.warning e.message
				end
			end
			# Substitute escape sequences
			@output.gsub!(ESCAPES) { |match| ($1 == '.') ? '' : $1 }
			toc[:contents].gsub!(ESCAPES) { |match| ($1 == '.') ? '' : $1 } rescue nil
			@topics.each do |t|
				t[:contents].gsub!(ESCAPES) { |match| ($1 == '.') ? '' : $1 }
			end
			@state = :finalized
		end

		# Returns the document output
		# @raise [RuntimeError] unless the document is finalized.
		def output
			raise RuntimeError, "Document is not finalized" unless finalized?
			@output
		end

		# @return [Boolean] Returns true if the document is new, false otherwise
		def new?
			@state == :new
		end

		# @return [Boolean] Returns true if the document is analyzed, false otherwise
		def analyzed?
			@state == :analyzed
		end

		# @return [Boolean] Returns true if the document is analyzed, false otherwise
		def finalized?
			@state == :finalized
		end

	end
	
end
