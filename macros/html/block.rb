#!/usr/bin/env ruby

macro :note do |node|
	%{
		<div class="#{node[:macro]}">
			<span class="note-title">#{node[:macro].capitalize}</span>
			<span class="note-body">#{node[:value]}</span>
		</div>
	}
end

macro :fig do |node|
	# TODO
	""
end

macro :code do |node|
	# TODO
	node[:value]
end

macro :table do |node|
	%{<table>#{node[:value]}</table>}
end

macro :tr do |node|
	%{<tr>#{node[:value]}</tr>}
end

macro :td do |node|
	%{<td>#{node[:value]}</td>}
end

macro :th do |node|
	%{<th>#{node[:value]}</th>}
end

macro_alias :important => :note
macro_alias :tip => :note
macro_alias :caution => :note
