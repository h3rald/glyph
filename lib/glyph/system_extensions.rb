# Core Symbol class.
class Symbol
  # Comparison operator based on the one in the String class.
	def <=>(b)
		self.to_s <=> b.to_s
	end
end

# Core String class.
class String
  # Converts the strings to "title case" (capitalizes each word).
	def title_case
		self.snake_case.split('_').map{|s| s.capitalize}.join(' ')
	end
end

# Core Hash class.
class Hash
  # Converts the hash to a string of Glyph options.
	def to_options(sep=" ")
		"".tap do |s|
			self.each_pair do |k, v|
				key = k.to_s
				s += key.length == 1 ? "-" : "--"
				s += key
				s += sep
				s += v.to_s =~ /\s/ ? "\"#{v}\"" : v.to_s
				s += " "
			end
		end.strip
	end
end

