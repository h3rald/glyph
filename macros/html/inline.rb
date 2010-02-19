#!/usr/bin/env ruby

macro :anchor do 
	ident, title = @params
	macro_error "Bookmark '#{ident}' already exists" if bookmark? ident
	bookmark :id => ident, :title => title
	%{<a id="#{ident}">#{title}</a>}
end

macro :link do
	href, title = @params
	if href.match /^#/ then
		anchor = href.gsub(/^#/, '').to_sym
		bmk = bookmark? anchor
		if bmk then
			title ||= bmk[:title]
		else
			plac = placeholder do |document|
				macro_error "Bookmark '#{anchor}' does not exist" unless document.bookmarks[anchor] 
				document.bookmarks[anchor][:title]
			end
			title ||= plac
		end
	end
	title ||= href
	%{<a href="#{href}">#{title}</a>}
end

macro :fmi do
	topic, href = @params
	link = placeholder do |document| 
		interpret "link[#{href}]"
	end
	%{<span class="fmi">for more information on #{topic}, see #{link}</span>}
end

macro_alias :bookmark => :anchor
macro_alias '#' => :anchor
macro_alias '=>' => :link
macro_alias '+' => :term
