module Glyph
	class Bookmark

		attr_reader :type, :id, :file, :title, :contents

		def initialize(hash)
			@contents = hash
			@id = hash[:id].to_sym rescue nil
			@file = hash[:file].to_sym rescue nil
			raise RuntimeError, "Bookmark ID not specified" unless @id
			raise RuntimeError, "Invalid bookmark ID: #{@id}" unless check_id
			@type = hash[:type] || :anchor
			@title = hash[:title]
		end

		def code
			@id
		end

		def ==(b)
			raise RuntimeError, "#{b.inspect} is not a bookmark" unless b.is_a? Glyph::Bookmark
			self.id == b.code && self.file == b.file
		end

		[:anchor, :header, :indexterm, :figure].each do |n|
			define_method "#{n}?".to_sym do
				@type == n
			end
		end

		def link(file=nil)
			if Glyph['document.output'].to_sym.in? Glyph['system.multifile_targets'] then
				"#{@file}##{@id}"
			else
				pre = (file.to_s == @file.to_s) ? "" : "#{@file.to_s.gsub(/[^a-z0-9_-]/i, '_')}___"
				"##{pre}#{@id}"
			end
		end

		def ref(file=nil)
			if Glyph['document.output'].to_sym.in? Glyph['system.multifile_targets'] then
				@id
			else
				pre = (file.to_s == @file.to_s) ? "" : "#{@file.to_s.gsub(/[^a-z0-9_-]/i, '_')}___"
				"#{pre}#{@id}"
			end
		end

		alias to_s ref

		private

		def check_id
			@id.to_s.match(/[^a-z0-9_-]/i) ? false : true
		end

	end

	class BookmarkCollection < Array 

		def push(el)
			raise RuntimeError, "'#{el}' is not a bookmark" unless el.is_a? Glyph::Bookmark
			raise RuntimeError, "Bookmark '#{el}' already defined" if self.include? el
			super
		end

		def get(ident, file)
			bmk = Glyph::Bookmark.new(:id => ident, :file => file)
			select{|b| b == bmk }[0] rescue nil
		end

		alias << push

	end
end
