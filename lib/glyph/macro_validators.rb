# encoding: utf-8

module Glyph
	class Macro

		# @since 0.2.0
		module Validators

			# Validates the macro according to the specified block
			# @param [String] message the message to display if the validation fails.
			# @param [Hash] options a hash containing validation options
			# @option options :level the error level (:error, :warning)
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

			# Ensures that the provided name is a valid XML element name.
			# @params [String, Symbol] name the element name to validate
			# @param [Hash] options a hash containing validation options (for now the only option is :level)
			# @return [Boolean] whether the validation passed or not
			# @since 0.3.0
			def valid_xml_element(name, options={:level => :error})
				validate("Invalid XML element '#{name}'", options) { name.to_s.match(/^([^[:punct:]0-9<>]|_)[^<>"']*/) }
			end

			# Ensures that a macro attribute name is a valid XML attribute name.
			# @param [String, Symbol] name the attribute name to validate
			# @param [Hash] options a hash containing validation options
			# @option options :level the error level (:error, :warning)
			# @return [Boolean] whether the validation passed or not
			# @since 0.3.0
			def valid_xml_attribute(name, options={:level => :warning})
				validate("Invalid XML attribute '#{name}'", options) { name.to_s.match(/^([^[:punct:]0-9<>]|_)[^<>"']*/) }
			end

			# Ensures that the macro receives up to _n_ parameters.
			# @param [Integer] n the maximum number of parameters allowed for the macro.
			# @param [Hash] options a hash containing validation options
			# @option options :level the error level (:error, :warning)
			# @return [Boolean] whether the validation passed or not
			def max_parameters(n, options={:level=>:error})
				validate("Macro '#{@name}' takes up to #{n} parameter(s) (#{@node.params.length} given)", options) do
					if n == 0 then
						no_parameters options
					else
						@node.params.length <= n 
					end
				end
			end

			# Ensures that the macro receives at least _n_ parameters.
			# @param [Integer] n the minimum number of parameters allowed for the macro.
			# @param [Hash] options a hash containing validation options
			# @option options :level the error level (:error, :warning)
			# @return [Boolean] whether the validation passed or not
			def min_parameters(n, options={:level=>:error})
				validate("Macro '#{@name}' takes at least #{n} parameter(s) (#{@node.params.length} given)", options) { @node.params.length >= n }
			end

			# Ensures that the macro receives exactly _n_ parameters.
			# @param [Integer] n the number of parameters allowed for the macro.
			# @param [Hash] options a hash containing validation options
			# @option options :level the error level (:error, :warning)
			# @return [Boolean] whether the validation passed or not
			def exact_parameters(n, options={:level=>:error})
				validate("Macro '#{@name}' takes exactly #{n} parameter(s) (#{@node.params.length} given)", options) do
					if n == 0 then
						no_parameters options
					else
						@node.params.length == n 
					end
				end
			end

			# Ensures that the macro receives the specified attribute
			# @param [String, Symbol] name the name of the attribute
			# @param [Hash] options a hash containing validation options
			# @option options :level the error level (:error, :warning)
			# @return [Boolean] whether the validation passed or not
			# @since 0.4.0
			def required_attribute(name, options={:level=>:error})
				validate("Macro '#{@name}' requires a '#{name}' attribute", options) do
					!raw_attribute(name.to_sym).blank?
				end
			end

			# Ensures that the macro receives no parameters.
			# @param [Hash] options a hash containing validation options
			# @option options :level the error level (:error, :warning)
			# @return [Boolean] whether the validation passed or not
			def no_parameters(options={:level=>:error})
				validate("Macro '#{@name}' takes no parameters (#{@node.params.length} given)", options) do 
					case @node.params.length
					when 0 then
						true
					when 1 then
						result = true
						@node.param(0).children.each do |p|
							result = p.is_a?(Glyph::TextNode) && p[:value].blank?
							break unless result
						end
						result
					else
						false
					end
				end
			end

			# Raises a macro error if Glyph is running in safe mode.
			# @raise [Glyph::MacroError] the macro cannot be used allowed in safe mode
			# @since 0.3.0
			def safety_check
				macro_error "Macro '#@name' cannot be used in safe mode" if Glyph.safe?
			end

			# Ensures that no mutual inclusion occurs within the specified parameter or attribute
			# @param [Fixnum, Symbol] the parameter index or attribute name to check
			# @raise [Glyph::MacroError] mutual inclusion was detected
			# @since 0.3.0
			def no_mutual_inclusion_in(arg)
				check_type = arg.is_a?(Symbol) ? :attribute : :parameter
				check_value = nil
				found = @node.find_parent do |n|
					if n.is_a?(Glyph::MacroNode) && Glyph::MACROS[n[:name]] == Glyph::MACROS[@name] then
						case check_type
						when :attribute then
							check_value = n.children.select do |node| 
								node.is_a?(Glyph::AttributeNode) && node[:name] == arg
							end[0][:value] rescue nil
							check_value == attr(arg) 
						when :parameter then
							check_value = n.children.select do |node| 
								node.is_a?(Glyph::ParameterNode) && node[:name] == :"#{arg}"
							end[0][:value] rescue nil
							check_value == param(arg) 
						end
					end
				end
				if found then
					macro_error "Mutual Inclusion in #{check_type}(#{arg}): '#{check_value}'", Glyph::MutualInclusionError 
				end
			end

			# Ensures that the macros is within another
			# @param [String, Symbol] arg the name of the container macro
			# @param [Hash] options a hash containing validation options
			# @option options :level the error level (:error, :warning)
			# @return [Boolean] whether the validation passed or not
			# @since 0.4.0
			def within(arg, options={:level => :error})
				validate("Macro '#{@name}' must be within a '#{arg}' macro", options) do 
					@node.find_parent {|n| Glyph.macro_eq? arg.to_sym, n[:name]}
				end
			end

			# Ensures that the macros is _not_ within another
			# @param [String, Symbol] arg the name of the container macro
			# @param [Hash] options a hash containing validation options
			# @option options :level the error level (:error, :warning)
			# @return [Boolean] whether the validation passed or not
			# @since 0.4.0
			def not_within(arg, options={:level => :error})
				validate("Macro '#{@name}' must not be within a '#{arg}' macro", options) do 
					!@node.find_parent {|n| Glyph.macro_eq? arg.to_sym, n[:name]}
				end
			end

		end
	end
end
