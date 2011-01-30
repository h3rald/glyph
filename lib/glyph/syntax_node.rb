# encoding: utf-8

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

		# @return [String] a textual representation of self
		# @since 0.4.0
		def inspect
			string = ""
			descend do |e, level|
				# Remove document key to avoid endless resursion
				hash = e.to_hash.reject{|k,v| k == :document}
				string << "  "*level+"(#{e.class})"+hash.inspect+"\n"
			end
			string.chomp
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
			"#{self[:name]}["+e+contents+e+"]"
		end

		def contents
			attributes.join+parameters.join("|")
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

		# @return [Array<Glyph::MacroNode>] an array of the child macro nodes
		# @since 0.4.0
		def child_macros
			macros = []
			parameters.each do |p|
				macros += p.children.select{|n| n.is_a? MacroNode }
			end
			macros
		end

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
			self[:source] = context[:source]
			self[:document] = context[:document] 
			self[:info] = context[:info]
			self[:value] = ""
			dispatched = parent_macro.dispatch(self) if parent_macro
			return dispatched if dispatched
			if Glyph['options.macro_set'] == "xml" || Glyph::MACROS[self[:name]].blank? && Glyph['options.xml_fallback'] then
				m = Glyph::MacroNode.new
				m[:name] = :xml
				Glyph::Macro.new(m).expand
				return m[:dispatch].call self
			end
			Glyph::Macro.new(self).expand
		end

		# Returns where the macro was used (used in Glyph::Analyzer)
		# @since 0.4.0
		def source
			s = self[:source][:file] rescue nil 
			s ||= self[:source][:name] rescue nil
			s
		end

		# @since 0.5.0
		# TODO: doc
		def dispatch(node)
			return self[:dispatch].call node if self[:dispatch]
			false
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

		# @return [String] a textual representation of the parameter contents
		# @since 0.3.0 
		def contents
			parent[:escape] ? ".[=#{children.join}=]" : children.join
		end

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
			self[:escape] ? ".[=#{children.join}=]" : children.join
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
