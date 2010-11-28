#!/usr/bin/env ruby
# encoding: utf-8

macro :section do 
	max_parameters 1
	if raw_attribute(:src) && Glyph.multiple_output_files? then
		required_attribute :title
	end
	@data[:name] = @name
	h = ""
	if attr(:title) then
		level = 1
		@node.ascend do |n| 
			break if n.respond_to?(:attribute) && n.attribute(:class) && n.attribute(:class).children.join.strip == "topic"
			#if n.is_a?(Glyph::MacroNode) && Glyph["system.structure.headers"].include?(n[:name]) then
			if n.is_a?(Glyph::MacroNode) && n[:name].in?(Glyph.titled_sections) then
				level+=1
			end
		end
		ident = (attr(:id) || "h_#{@node[:document].headers.length+1}").to_sym
		# The bookmark is added when the section is first processed; therefore it will exist already when a topic layout is processed
		bmk = @node[:document].bookmark?(ident)
		bmk ||=  header	:title => attr(:title), 
			:level => level, 
			:id => ident, 
			:toc => !attr(:notoc),
			:definition => @source_file,
			:file => (attr(:src) || @source_file)
		@node[:header] = bmk
		@data[:title] = attr :title
		@data[:level] = level
		@data[:id] = bmk.code
	end
	if attr(:src) then 
		# Create topic
		if Glyph.multiple_output_files? 
			topic_id = (attr(:id) || "t_#{@node[:document].topics.length}").to_sym
			layout = attr(:layout) || Glyph["output.#{Glyph['document.output']}.layouts.topic"] || :topic
			layout_name = "layout/#{layout}".to_sym
			macro_error "Layout '#{layout}' not found" unless Glyph::MACROS[layout_name]
			result = interpret %{#{layout_name}[
											@title[#{attr(:title)}]
											@id[#{topic_id}]
											@contents[include[@topic[true]#{attr(:src)}]]
									]}
									bmk = @node[:document].bookmark? topic_id
									if bmk then
										# Fix file for topic bookmark
										@node[:document].bookmark?(topic_id).file = attr(:src)
									else
										bookmark :title => attr(:title), :id => topic_id, :file => attr(:src), :definition => @source_file
									end
									topic_src = attr(:src)
									topic_src += ".glyph" unless topic_src.match /\..+$/
										@node[:document].topics << {:src => topic_src, :title => attr(:title), :id => topic_id, :contents => result}
									# Process section contents
									@data[:content] = value
		else
			v = raw_value
			@node.children.delete_if{|c| !c.is_a?(Glyph::AttributeNode)}
			body = interpret "include[#{attr(:src)}]#{v}"
			@data[:content] = body
		end
	else
		@data[:content] = value
	end
	render
end

macro :article do
	exact_parameters 1
	head = raw_attr(:head)
 	head ||= %{style[default.css]}
	pre_title = raw_attr(:"pre-title")
	post_title = raw_attr(:"post-title")
	pubdate = @node.attr(:pubdate) ? "pubdate[#{@node.attr(:pubdate).contents}]" : "pubdate[]"
	halftitlepage = raw_attr(:halftitlepage)
	halftitlepage ||= %{
			#{pre_title}
			title[]
			subtitle[]
			author[]
			#{pubdate}
			#{post_title}
	}
	interpret %{document[
	head[#{head}]
	body[
		halftitlepage[
			#{halftitlepage}
		]
		#{@node.value}
	]
]}	
end

macro :book do
	no_parameters
	head = raw_attr(:head) 
	head ||= %{style[default.css]}
	pre_title = raw_attr(:"pre-title")
	post_title = raw_attr(:"post-title")
	titlepage = raw_attr(:titlepage)
	pubdate = @node.attr(:pubdate) ? "pubdate[#{@node.attr(:pubdate).contents}]" : "pubdate[]"
	titlepage ||= %{
			#{pre_title}
			title[]
			subtitle[]
			revision[]
			author[]
			#{pubdate}
			#{post_title}
	}
	frontmatter = raw_attr(:frontmatter)
	bodymatter = raw_attr(:bodymatter)
	backmatter = raw_attr(:backmatter)
	frontmatter = "frontmatter[\n#{frontmatter}\n]" if frontmatter
	bodymatter = "bodymatter[\n#{bodymatter}\n]" if bodymatter
	backmatter = "backmatter[\n#{backmatter}\n]" if backmatter
	interpret %{document[
	head[#{head}]
	body[
		titlepage[
			#{titlepage}
		]
		#{frontmatter}
		#{bodymatter}
		#{backmatter}
	]
]}	
end


macro :document do
	exact_parameters 1
	@data[:content] = value
	render
end

macro :head do
	exact_parameters 1
	@data[:author] = Glyph['document.author'].blank? ? "" : render(:meta, :name => "author", :content => Glyph['document.author'])
	@data[:copyright] = Glyph['document.author'].blank? ? "" : render(:meta, :name => "copyright", :content => Glyph['document.author'])
	@data[:content] = value
	render
end

macro :style do 
	within :head
	exact_parameters 1
	file = Glyph.lite? ? Pathname.new(value) : Glyph::PROJECT/"styles/#{value}"
	file = Pathname.new Glyph::HOME/'styles'/value unless file.exist?
	macro_error "Stylesheet '#{value}' not found" unless file.exist?
	@node[:document].style file
	@data[:file] = file
	render
end

macro :toc do 
	if @node[:document].toc[:contents] then
		@node[:document].toc[:contents] 
	else
		max_parameters 1
		depth = param(0)
		toc = placeholder do |document|
			descend_section = lambda do |n1, added_headers|
				list = ""
				added_headers ||= []
				n1.descend do |n2, level|
					#if n2.is_a?(Glyph::MacroNode) && Glyph['system.structure.headers'].include?(n2[:name]) then
					if n2.is_a?(Glyph::MacroNode) && n2[:name].in?(Glyph.titled_sections) then
						if Glyph.multiple_output_files? then
							# Only consider topics/booklets when building TOC for web/web5
							next if !n2.attribute(:src) && n2.child_macros.select{|child| child.attribute(:src)}.blank? 
						end
						next if n2.find_parent{|node| Glyph['system.structure.special'].include? node[:name] }
						header_obj = n2[:header]
						next if depth && header_obj && (header_obj.level-1 > depth.to_i) || header_obj && !header_obj.toc?
						next if added_headers.include? header_obj
						added_headers << header_obj
						# Check if part of frontmatter, bodymatter or backmatter
						container = n2.find_parent do |node| 
							node.is_a?(Glyph::MacroNode) && 
								node[:name].in?([:frontmatter, :bodymatter, :appendix, :backmatter])
						end[:name] rescue nil
						if header_obj then 
							if (!Glyph.multiple_output_files? || (header_obj.definition != header_obj.file)) then
								link_header = render(:link, :title => header_obj.title, :target => header_obj.link(@source_file))
							else
								link_header =	header_obj.title
							end
							list << render(:toc_item, :classes => [container, n2[:name]], :title => link_header) 
						end
						child_list = ""
						n2.child_macros.each do |c|
							child_list << descend_section.call(c, added_headers)
						end	
						list << render(:toc_sublist, :contents => child_list) unless child_list.blank?
					end
				end
				list
			end
			title ||= "Table of Contents"
			bmk = @node[:document].bookmark?(:toc) || bookmark(:id => :toc, :file => @source_file, :title => title)
			@data[:toc_id] = bmk.to_s
			@data[:title] = bmk.title
			@data[:document] = document
			@data[:descend_section] = descend_section
			render
		end
		@node[:document].toc[:contents] = toc.to_s
		toc
	end
end

# See:
#  http://microformats.org/wiki/book-brainstorming
#  http://en.wikipedia.org/wiki/Book_design

(Glyph['system.structure.frontmatter'] + Glyph['system.structure.bodymatter'] + Glyph['system.structure.backmatter']).
	each {|s| macro_alias s => :section }

macro_alias "§" => :section
macro_alias :frontcover => :section
macro_alias :titlepage => :section
macro_alias :halftitlepage => :section
macro_alias :frontmatter => :section
macro_alias :bodymatter => :section
macro_alias :backmatter => :section
macro_alias :backcover => :section
