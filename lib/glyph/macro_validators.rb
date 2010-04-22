module Glyph
	class Macro

		module Validators

			# Validates the macro according to the specified block
			# @param [String] message the message to display if the validation fails.
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			# @example
			#     validate("Invalid macro value", :level => :error) {@value == 'valid'} # Raises an error in case of failure
			#     validate("Invalid macro value", :level => :warning) {@value == 'valid'} # Displays a warning in case of failure
			def validate(message, options={:level => :error}, &block)
				unless instance_eval(&block) then
					send("macro_#{options[:level]}".to_sym, message)
				end
			end

			# Ensures that the macro receives up to _n_ parameters.
			# @param [Integer] n the maximum number of parameters allowed for the macro.
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			def max_parameters(n, options={:level=>:error})
				validate("Macro '#{@name}' takes up to #{n} parameter(s) (#{@params.length} given)", options) { @params.length <= n }
			end

			# Ensures that the macro receives at least _n_ parameters.
			# @param [Integer] n the minimum number of parameters allowed for the macro.
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			def min_parameters(n, options={:level=>:error})
				validate("Macro '#{@name}' takes at least #{n} parameter(s) (#{@params.length} given)", options) { @params.length >= n }
			end

			# Ensures that the macro receives exactly _n_ parameters.
			# @param [Integer] n the number of parameters allowed for the macro.
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			def exact_parameters(n, options={:level=>:error})
				validate("Macro '#{@name}' takes exactly #{n} parameter(s) (#{@params.length} given)", options) { @params.length == n }
			end

			# Ensures that the macro receives no parameters.
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			def no_parameters(options={:level=>:error})
				validate("Macro '#{@name}' takes have parameter(s) (#{@params.length} given)", options) { @params.length == 0 }
			end

		end

	end
end
