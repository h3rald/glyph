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
				f = (file.to_sym == @file) ? "" : @file rescue nil
				"#{f}##{@id}"
			else
				"##{@file.to_s.gsub(/[^a-z0-9_-]/i, '_')}___#{@id}"
			end
		end

		def ref(file=nil)
			if Glyph['document.output'].to_sym.in? Glyph['system.multifile_targets'] then
				@id.to_s
			else
				"#{@file.to_s.gsub(/[^a-z0-9_-]/i, '_')}___#{@id}"
			end
		end

		alias to_s ref
		alias to_str ref

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

	class BookmarkCollection < Array 

		def push(el)
			raise RuntimeError, "'#{el}' is not a bookmark" unless el.is_a? Glyph::Bookmark
			raise RuntimeError, "Bookmark '#{el}' already defined" if self.include? el
			super
		end

		def get(ident, file=nil)
			bmk = Glyph::Bookmark.new(:id => ident, :file => file)
			select{|b| b == bmk }[0] rescue nil
		end

		alias << push

	end
end
