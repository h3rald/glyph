module Glyph
	class Macro

		# @since 0.2.0
		module Validators

			# Validates the macro according to the specified block
			# @param [String] message the message to display if the validation fails.
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			# @return [Boolean] whether the validation passed or not
			# @example
			#     validate("Invalid macro value", :level => :error) {value == 'valid'} # Raises an error in case of failure
			#     validate("Invalid macro value", :level => :warning) {value == 'valid'} # Displays a warning in case of failure
			def validate(message, options={:level => :error}, &block)
				result = instance_eval(&block)
				unless result then
					send("macro_#{options[:level]}".to_sym, message)
				end
				result
			end

			# Validates the value of a macro parameter (specified by name or position) according to the specified regular expression.
			# @param [String,Integer] name the parameter name (or position) to validate
			# @param [Regexp] regexp the regular expression used for the validation
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			# @return [Boolean] whether the validation passed or not
			# @since 0.3.0
			def valid_parameter_value(name, regexp, message, options={:level => :warning})
				validate(message, options) { param(name).to_s.match(regexp) }
			end

			# Validates the name of a macro parameter (specified by name or position) according to the specified regular expression.
			# @param [String,Integer] name the parameter name to validate
			# @param [Regexp] regexp the regular expression used for the validation
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			# @return [Boolean] whether the validation passed or not
			# @since 0.3.0
			def valid_parameter_name(name, regexp, message, options={:level => :warning})
				validate(message, options) { name.to_s.match(regexp) }
			end

			# Ensures that the macro element attributes is a valid XML element name.
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			# @return [Boolean] whether the validation passed or not
			# @since 0.3.0
			def valid_xml_element(options={:level => :error})
				validate("Invalid XML element '#{@node[:element]}'", options) { @node[:element].to_s.match(/^([^[:punct:]0-9<>]|_)[^<>"']*/) }
			end

			# Ensures that a macro parameter is a valid XML attribute name.
			# @param [String,Integer] name the parameter name (or position) to validate
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			# @return [Boolean] whether the validation passed or not
			# @since 0.3.0
			def valid_xml_attribute(name, options={:level => :warning})
				valid_parameter_name(name, /^([^[:punct:]0-9<>]|_)[^<>"']*/, "Invalid XML attribute '#{attr(name)}'", options)
			end

			# Ensures that the macro receives up to _n_ parameters.
			# @param [Integer] n the maximum number of parameters allowed for the macro.
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			# @return [Boolean] whether the validation passed or not
			def max_parameters(n, options={:level=>:error})
				validate("Macro '#{@name}' takes up to #{n} parameter(s) (#{raw_parameters.length} given)", options) { raw_parameters.length <= n }
			end

			# Ensures that the macro receives at least _n_ parameters.
			# @param [Integer] n the minimum number of parameters allowed for the macro.
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			# @return [Boolean] whether the validation passed or not
			def min_parameters(n, options={:level=>:error})
				validate("Macro '#{@name}' takes at least #{n} parameter(s) (#{raw_parameters.length} given)", options) { raw_parameters.length >= n }
			end

			# Ensures that the macro receives exactly _n_ parameters.
			# @param [Integer] n the number of parameters allowed for the macro.
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			# @return [Boolean] whether the validation passed or not
			def exact_parameters(n, options={:level=>:error})
				validate("Macro '#{@name}' takes exactly #{n} parameter(s) (#{raw_parameters.length} given)", options) { raw_parameters.length == n }
			end

			# Ensures that the macro receives no parameters.
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			# @return [Boolean] whether the validation passed or not
			def no_parameters(options={:level=>:error})
				validate("Macro '#{@name}' takes no parameters (#{raw_parameters.length} given)", options) { raw_parameters.length == 0 }
			end

		end

	end
end
