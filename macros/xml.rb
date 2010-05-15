#!/usr/bin/env ruby

# TODO add attributes support and character validation
macro "|xml|" do
	valid_xml_element
	name = @node[:element]
	attributes = named_params.values.
		sort{|a,b| a[:order] <=> b[:order]}.
		map do |e| 
			if valid_xml_attribute(e[:name]) then
				%|#{e[:name]}="#{e[:value]}"|
			else
				nil
			end
		end.compact.join(" ")
	attributes = " "+attributes unless attributes.blank?
	%{<#{name}#{attributes}>#{params.last}</#{name}>}
end
