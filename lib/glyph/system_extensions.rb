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

