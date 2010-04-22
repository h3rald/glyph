module Glyph
	class Macro

		module Validators

			def validate(message, options={:level => :error}, &block)
				unless instance_eval(&block) then
					send("macro_#{options[:level]}".to_sym, message)
				end
			end

			def max_parameters(n, options={:level=>:error})
				validate("Macro '#{@name}' takes up to #{n} parameter(s) (#{@params.length} given)", options) { @params.length <= n }
			end

			def min_parameters(n, options={:level=>:error})
				validate("Macro '#{@name}' takes at least #{n} parameter(s) (#{@params.length} given)", options) { @params.length >= n }
			end

			def exact_parameters(n, options={:level=>:error})
				validate("Macro '#{@name}' takes exactly #{n} parameter(s) (#{@params.length} given)", options) { @params.length == n }
			end

			def no_parameters(options={:level=>:error})
				validate("Macro '#{@name}' takes have parameter(s) (#{@params.length} given)", options) { @params.length == 0 }
			end

		end

	end
end
