module Glyph

	# A subclass of Glyph::SyntaxNode is instantiated by Glyph::Parser whenever a known
	# text element is parsed.
	# @since 0.3.0
	class SyntaxNode < Node

		# @return [String] an empty string 
		# @since 0.3.0
		def to_s
			""
		end

		# @return [String] the value of the :value key
		# @since 0.3.0
		def evaluate(context, options={})
			self[:value]
		end

		# @return [Glyph::MacroNode] the first Glyph::MacroNode ancestor
		# @since 0.3.0
		def parent_macro
			find_parent{|n| n.is_a?(MacroNode)}
		end

	end

	# The root element of any Glyph Abstract Syntax Tree
	# @since 0.3.0
	class DocumentNode < SyntaxNode

		# @return [String] the value of the children node
		# @since 0.3.0
		def evaluate(context)
			self[:value] = ""
			self.children.each {|c| self[:value] << c.evaluate(context) }
			self[:value]
		end
			
	end

	# A Glyph macro in Glyph Abstract Syntax Tree
	# @since 0.3.0 
	class MacroNode < SyntaxNode

		# @return [String] a textual representation of the macro
		# @since 0.3.0
		def to_s
			e = self[:escape] ? "=" : ""
			"#{self[:name]}["+e+attributes.join+parameters.join("|")+e+"]"
		end

		# Expands the macro
		# @return [String] the value of the macro
		# @since 0.3.0
		def evaluate(context, options={})
			self[:value] = expand(context)
		end

		# @return [Array<Glyph::ParameterNode>] an array of the child parameter nodes
		# @since 0.3.0
		def parameters
			children.select{|n| n.is_a? ParameterNode }
		end

		# 
		# Returns the parameter syntax node at the specified index
		# @param [Fixnum] n the index of the parameter 
		# @return [Glyph::ParameterNode, nil] a parameter node
		# @since 0.3.0
		def parameter(n)
			parameters[n]
		end

		# Equivalent to Glyph::MacroNode#parameter(0).
		# @since 0.3.0
		def value
			parameter(0)
		end

		# @return [Array<Glyph::AttributeNode>] an array of the child attribute nodes
		# @since 0.3.0 
		def attributes
			children.select{|n| n.is_a? AttributeNode }
		end

		# Returns the attribute syntax node with the specified name  
		# @param [Symbol] name the name of the attribute
		# @return [Glyph::AttributeNode, nil] an attribute node
		# @since 0.3.0
		def attribute(name)
			attributes.select{|n| n[:name] == name}[0]
		end

		alias attr attribute
		alias param parameter
		alias attrs attributes
		alias params parameters

		# Expands the macro corresponding to self[:name]
		# @param [Glyph::MacroNode] context the context of the macro
		# @return [String] the value of the macro
		# @since 0.3.0 
		def expand(context)
			xml_element(context)	
			self.merge!({
				:source => context[:source], 
				:document => context[:document], 
				:info => context[:info],
				:value => ""
			})
			Glyph::Macro.new(self).expand
		end

		protected

		def xml_element(context)
			known_macro = Glyph::MACROS.include? self[:name]
			name = self[:name].to_s
			if !known_macro && name.match(/^=(.+)/) then
				# Force tag name override if macro starts with a '='
				name.gsub! /^=(.+)/, '\1' 
			end
			case
				# Use XML syntax
			when Glyph['language.set'] == 'xml' then
				self[:element] = name
				self[:name] = :"|xml|" 
				# Fallback to XML syntax
			when Glyph['language.options.xml_fallback'] then
				unless known_macro then
					self[:element] = name
					self[:fallback] = true
					self[:name] = :"|xml|" 
				end
			else
				# Unknown macro
				raise Glyph::RuntimeError, "Undefined macro '#{name}'\n -> source: #{context[:source]}" unless known_macro
			end
		end

	end

	# A piece of text in Glyph Abstract Syntax Tree
	# @since 0.3.0 
	class TextNode < SyntaxNode

		# @return [String] the text itself
		def to_s
			self[:value]
		end

	end

	# A Glyph macro parameter in Glyph Abstract Syntax Tree
	# @since 0.3.0 
	class ParameterNode < SyntaxNode

		# @return [String] a textual representation of the parameter node
		# @since 0.3.0 
		def to_s
			children.join
		end

		alias contents to_s

		# @param [Glyph::MacroNode] context the context of the macro
		# @param [Hash] options a hash of options
		# @option options [Boolean] :params whether to evaluate child nodes or not
		# @return [String] the evaluated child nodes
		# @since 0.3.0 
		def evaluate(context, options={:params => false})
			self[:value] = ""
			self.children.each {|c| self[:value] << c.evaluate(context) } if options[:params]
			self[:value]
		end

	end

	# A Glyph macro attribute in Glyph Abstract Syntax Tree
	# @since 0.3.0 
	class AttributeNode < SyntaxNode

		# @return [String] a textual representation of the attribute node
		# @since 0.3.0 
		def to_s
			e = self[:escape] ? "=" : ""
			"@#{self[:name]}["+e+children.join+e+"]"
		end

		# @return [String] a textual representation of the attribute contents
		# @since 0.3.0 
		def contents
			children.join
		end

		# @param [Glyph::MacroNode] context the context of the macro
		# @param [Hash] options a hash of options
		# @option options [Boolean] :attrs whether to evaluate child nodes or not
		# @return [String] the evaluated child nodes
		# @since 0.3.0 
		def evaluate(context, options={:attrs => false})
			self[:value] = ""
			self.children.each {|c| self[:value] << c.evaluate(context) } if options[:attrs]
			self[:value]
		end

	end

	# Some escaped text within Glyph Abstract Syntax Tree
	# @since 0.3.0
	class EscapeNode < SyntaxNode

		# Returns the escaped value
		def to_s
			self[:value]
		end

	end

end
