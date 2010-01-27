#!/usr/bin/env ruby

macro :section do |node| 
	%{
		<div class="#{node[:macro]}">
			#{node[:value]}
		</div>
	}	
end

macro :header do |node|
	node.get_header
	%{
		<h#{node[:level]} id="#{node[:id]}">#{node[:header]}</h#{node[:level]}>
	}	
end

macro_alias :chapter => :section
macro_alias :part => :section
macro_alias :heading => :header
