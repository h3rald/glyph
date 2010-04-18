module Glyph
	class Macro

		module Validators

			def validate(message, &block)
				unless instance_eval(&block) then
					@node[:document].errors << message
					macro_error message
				end
			end

			def max_parameters(n)
				validate("Macro '#{@name}' takes up to #{n} parameter(s) (#{@params.length} given)") { @params.length <= n }
			end

			def min_parameters(n)
				validate("Macro '#{@name}' takes at least #{n} parameter(s) (#{@params.length} given)") { @params.length >= n }
			end

			def exact_parameters(n)
				validate("Macro '#{@name}' takes exactly #{n} parameter(s) (#{@params.length} given)") { @params.length == n }
			end

			def no_parameters
				validate("Macro '#{@name}' takes have parameter(s) (#{@params.length} given)") { @params.length == 0 }
			end

		end

	end
end
