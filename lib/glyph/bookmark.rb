module Glyph
	class Bookmark

		attr_reader :title, :file

		def initialize(hash)
			@id = hash[:id].to_sym rescue nil
			@file = hash[:file].to_sym rescue nil
			@title = hash[:title]
			raise RuntimeError, "Bookmark ID not specified" unless @id
			raise RuntimeError, "Invalid bookmark ID: #{@id}" unless check_id
		end

		def code
			@id
		end

		def ==(b)
			raise RuntimeError, "#{b.inspect} is not a bookmark" unless b.is_a? Glyph::Bookmark
			self.code == b.code && self.file == b.file
		end

		def link(file=nil)
			if Glyph['document.output'].to_sym.in? Glyph['system.multifile_targets'] then
				raise RuntimeError, "document.extension not set" if Glyph['document.extension'].blank?
				f = (file.to_sym == @file) ? "" : @file.to_s.gsub(/\..+$/, Glyph['document.extension']) rescue nil
				"#{f}##{@id}"
			else
				"##{@id}"
			end
		end

		def to_s
			@id.to_s
		end

		alias to_str to_s

		private

		def check_id
			@id.to_s.match(/[^a-z0-9_-]/i) ? false : true
		end

	end

	class Header < Bookmark

		attr_reader :level

		def initialize(hash)
			super(hash)
			@level = hash[:level]
			@toc = hash[:toc]
		end

		def toc?
			@toc
		end

	end

end
