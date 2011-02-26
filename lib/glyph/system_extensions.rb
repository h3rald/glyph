class Symbol
	def <=>(b)
		self.to_s <=> b.to_s
	end
end

class String
	def title_case
		self.snake_case.split('_').map{|s| s.capitalize}.join(' ')
	end
end

class Hash
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

