# encoding: utf-8

module Glyph

	# @since 0.4.0
	# This class is used to model bookmarks within a Glyph document. It contains methods to store 
	# bookmark data and resolve link paths automatically.
	class Bookmark

		attr_accessor :title, :file, :definition

		# Initializes a bookmark object from a hash containing bookmark data.
		# @param [Hash] hash the bookmark hash
		# @option hash [String] :id the bookmark ID
		# @option hash [String] :file the file containing the bookmark
		# @option hash [String] :title the title of the bookmark
		# @option hash [String] :definition the file where the bookmark was defined
		# @raise [RuntimeError] if the bookmark ID is not specified
		# @raise [RuntimeError] if the bookmark ID is invalid (it must contain only letters, numbers, - or _)
		def initialize(hash)
			@id = hash[:id].to_sym rescue nil
			@file = hash[:file]
			@title = hash[:title]
			@definition = hash[:definition]
			raise RuntimeError, "Bookmark ID not specified" unless @id
			raise RuntimeError, "Invalid bookmark ID: #{@id}" unless check_id
		end

		# Returns the bookmark ID.
		def code
			@id
		end

		# Returns true if the two bookmarks have the same ID and file
		# @param [Glyph::Bookmark] b the bookmark to compare
		# @raises [RuntimeError] if the parameter supplied is not a bookmark
		def ==(b)
			raise RuntimeError, "#{b.inspect} is not a bookmark" unless b.is_a? Glyph::Bookmark
			self.code == b.code && self.file == b.file
		end

		# Returns the appropriate link path to the bookmark, depending on the specified file
		# @param [String] file the file where the link to the bookmark must be placed
		#	@return [String] the link to the bookmark
		def link(file=nil)
			if multiple_output_files? then
				dest_file = @file.to_s
				dest_file += '.glyph' unless dest_file.match /\..+$/
				dest_file.gsub!(/^text\//, '') unless Glyph.lite?
				external_file = dest_file.to_s.gsub(/\..+$/, Glyph["output.#{Glyph['document.output']}.extension"]) 
				f = (file.blank? || file != @file) ? "#{Glyph["output.#{Glyph['document.output']}.base"]}#{external_file}" : ""
				"#{f}##{@id}"
			else
				"##{@id}"
			end
		end

		# Returns the bookmark id
		# @return [String] the bookmark ID
		def to_s
			@id.to_s
		end

		alias to_str to_s

		private

		def check_id
			@id.to_s.match(/[^a-z0-9_-]/i) ? false : true
		end

	end

	# This class is used to model bookmark headers
	class Header < Bookmark

		attr_reader :level

		# Initializes the bookmark from a hash. The header hash takes two additional options: 
		# :level (the header level within the document), :toc (whether the header should appear in the Table of Contents or not)
		def initialize(hash)
			super(hash)
			@level = hash[:level]
			@toc = hash[:toc]
		end

		# Returns true if the header is displayed in the Table of contents
		def toc?
			@toc
		end

	end

end
