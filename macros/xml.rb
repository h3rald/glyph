#!/usr/bin/env ruby

macro "|xml|" do
	begin
		valid_xml_element
		max_parameters 1
	rescue Exception => e
		if @node[:fallback] then
			macro_error "Unknown macro '#{@node[element]}'"
		else
			raise
		end
	end
	name = @node[:element]
 	if name.to_s.in? Glyph['language.options.xml_blacklist'] then
		""
	else
		attributes # evaluate attributes
		xml_attributes = @node.children.select{|node| node.is_a?(Glyph::AttributeNode)}.
			map do |e| 
			if valid_xml_attribute(e[:name]) then
				%|#{e[:name]}="#{e[:value]}"|
			else
				nil
			end
			end.compact.join(" ")
			xml_attributes = " "+xml_attributes unless xml_attributes.blank?
			end_first_tag = param(0) ? ">" : ""
			end_tag = param(0) ? "</#{name}>" : " />"
			contents = (raw_param(0)&0) && (raw_param(0)&0)[:element] ? "\n#{param(0)}\n" : param(0)
			%{<#{name}#{xml_attributes}#{end_first_tag}#{contents}#{end_tag}}
	end
end
