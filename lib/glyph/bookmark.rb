module Glyph
	class Bookmark

		attr_reader :type, :id, :file, :title

		def initialize(hash)
			@id = hash[:id].to_sym rescue nil
			@file = hash[:file].to_sym rescue nil
			raise RuntimeError, "Bookmark ID not specified" unless @id
			raise RuntimeError, "Bookmark file not specified" unless @file
			raise RuntimeError, "Invalid bookmark ID: #{@id}" unless check_id
			@type = hash[:type] || :anchor
			@title = hash[:title]
		end

		def ==(b)
			self.id == b.id && self.file == b.file
		end

		[:anchor, :header, :indexterm, :figure].each do |n|
			define_method "#{n}?".to_sym do
				@type == n
			end
		end

		def ref
			if Glyph['document.output'].to_sym.in? Glyph['system.multifile_targets'] then
				"#{@file}##{@id}"
			else
				"#{@file.to_s.gsub(/[^a-z0-9_-]/i, '_')}___#{@id}"
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
			select{|b| b.id == ident.to_sym && b.file == file.to_sym}[0] rescue nil
		end

		alias << push

	end
end
