#!/usr/bin/env ruby
# encoding: utf-8

macro :xml do
	dispatch do |node|
		name = node[:name]
		valid_xml_element name
		max_parameters 1
		if Glyph["options.xml_blacklist"] && name.to_s.in?(Glyph['options.xml_blacklist']) then
			""
		else
			attributes # evaluate attributes
			xml_attributes = node.children.select{|n| n.is_a?(Glyph::AttributeNode)}.map do |e| 
				if valid_xml_attribute(e[:name]) then
					attr_v = e[:value].blank? ? e.evaluate(node, :attrs => true) : e[:value]
					%|#{e[:name]}="#{attr_v}"|
				else
					nil
				end
			end.compact.join(" ")
			xml_attributes = " "+xml_attributes unless xml_attributes.blank?
			end_first_tag = node.param(0) ? ">" : ""
			end_tag = node.param(0) ? "</#{name}>" : " />"
			if node.param(0) then
				param_0 = node.param(0)[:value].blank? ? node.param(0).evaluate(node, :params => true) : node.param(0)[:value]
				if (node.param(0)&0) && (node.param(0)&0)[:name] then
					contents = "\n#{param_0}\n" 
				else
					contents = param_0
				end
			else
				# no parameters
				contents = ""
			end
			%{<#{name}#{xml_attributes}#{end_first_tag}#{contents}#{end_tag}}
		end
	end
end
