#!/usr/bin/env ruby

# TODO add attributes support and character validation
macro "==xml" do
	name = @node[:xml_element]
	%{<#{name}>#{@value}</#{name}>}
end
