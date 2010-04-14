module Glyph
	class Macro

		module Validators

			def validate(message, &block)
				macro_error message unless instance_eval(&block)
			end

			def allowed_ancestors(*args)
				validate("Macro '#{@name}' is not allowed here (allowed ancestors: #{args.join(', ')})") { @node.find_parent { |n| n[:macro].in? args.map{|a| a.to_sym} }}
			end

			def allowed_parents(*args)
				validate("Macro '#{@name}' is not allowed here (allowed parents: #{args.join(', ')})")  { @node.parent[:macro].in? args.map{|a| a.to_sym} }
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
