module Glyph

	module Language

		def evaluate(context)
			case self[:type]
			when :macro then
				self[:value] = expand_macro(context)
			when :attribute then
				self[:value] = ""
				self.children.each {|c| self[:value] << c.evaluate(context) }
			when :parameter then
				self[:value] = ""
				self.children.each {|c| self[:value] << c.evaluate(context) }
			when :document then
				self[:value] = ""
				self.children.each {|c| self[:value] << c.evaluate(context) }
			end
			self[:value]
		end

		def expand_macro(context)
			set_xml_element	
			self.merge!({
				:source => context[:source], 
				:document => context[:document], 
				:info => context[:info]
			})
			self[:value] = ""
			self.children.each do |child|
				self[:value] << child.evaluate(self)
			end
			Glyph::Macro.new(self).expand
		end

		def set_xml_element
			known_macro = Glyph::MACROS.include? self[:name]
			name = self[:name].to_s
			element = nil
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
					self[:name] = :"|xml|" 
				end
			else
				# Unknown macro
				raise Glyph::RuntimeError, "Undefined macro '#{name}'\n -> source: #{current[:source]}" unless known_macro
			end
		end

	end

	class Parser::SyntaxNode
		include Glyph::Language
	end

	# A Glyph::Interpreter object perform the following actions:
	# * Parses a string of text containing Glyph macros
	# * Creates a document based on the parsed syntax tree
	# * Analyzes and finalizes the document
	class Interpreter

		# Creates a new Glyph::Interpreter object.
		# @param [String] text the string to interpret
		# @param [Hash] context the context to pass along when expanding macros
		def initialize(text, context={})
			@context = context
			@context.merge! :source => '--'
			@parser = Glyph::Parser.new text, @context[:source]
			@text = text
		end

		# @see Glyph::Document#analyze
		def process
			parse unless @tree
			@document.analyze
		end

		# @see Glyph::Document#finalize
		def postprocess
			@document.finalize
		end

		# Returns the finalized @document (calls self#process and self#postprocess if necessary)
		# @return [Glyph::Document] the finalized document
		def document
			parse unless @tree
			return @document if @document.finalized?
			process if @document.new?
			postprocess if @document.analyzed?
			@document
		end

		def parse
			Glyph.info "  -> Parsing: #{@context[:source_name]}" if Glyph.debug? && @context[:info] && @context[:source_name]
			@tree = @parser.parse
			@document = Glyph::Document.new @tree, @context
			@document.inherit_from @context[:document] if @context[:document]
			@tree
		end
	
	end
end


