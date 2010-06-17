module Glyph
	class Bookmark

		attr_reader :type, :id, :file, :title

		def initialize(hash)
			@id = hash[:id].to_sym
			@file = hash[:file]
			raise RuntimeError, "Bookmark ID not specified" unless @id
			raise RuntimeError, "Bookmark file not specified" unless @file
			raise RuntimeError, "Invalid bookmark ID: #{@id}" unless check_id
			@type = hash[:type] || :anchor
			@title = hash[:title]
		end

		def check(hash)
			hash.each_pair do |key, value|
				if respond_to? key then
					return nil unless send(key) == value
				else
					return nil
				end
			end	
			self
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
				"#{@file.gsub(/[^a-z0-9_-]/i, '_')}___#{@id}"
			end
		end

		private

		def check_id
			@id.to_s.match(/[^a-z0-9_-]/i) ? false : true
		end

	end
end
