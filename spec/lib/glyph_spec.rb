#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph do

	before do
		Glyph.enable 'project:create'
	end

	it "should initialize a rake app and tasks" do
		Glyph::APP.tasks.length.should > 0
	end

	it "should run rake tasks" do
		create_project_dir
		Glyph.run 'project:create', Glyph::PROJECT
		lambda { Glyph.run! 'project:create', Glyph::PROJECT }.should raise_error
		delete_project_dir
		create_project_dir
		lambda { Glyph.run! 'project:create', Glyph::PROJECT }.should_not raise_error
		delete_project_dir
	end

	it "should define macros" do
		lambda { define_em_macro }.should_not raise_error
		lambda { define_ref_macro }.should_not raise_error
		Glyph::MACROS.include?(:em).should == true
		Glyph::MACROS.include?(:ref).should == true
	end

	it "should support macro aliases" do
		define_ref_macro
		lambda { Glyph.macro_alias("->" => :ref)}.should_not raise_error
		Glyph::MACROS[:"->"].should == Glyph::MACROS[:ref]
		Glyph.macro_alias :em => :ref
		Glyph::MACROS[:em].should_not == Glyph::MACROS[:ref]
	end

	it "should provide a set of default macros and aliases" do
		Glyph.run! 'load:all'
		macros = [:anchor, :link, :fmi, :note, :box, :code, :title, :subtitle,
		:img, :fig, :author, :pubdate, :table, :td, :tr, :th, :comment, :todo, :snippet,
		:include, :config, :ruby, :escape, :textile, :markdown, :div, :header, :document, :body,
		:head, :style, :toc, :section]
		aliases = [	
			[[:bookmark, "#"], :anchor],
			[["=>"], :link],
			[[:important, :caution, :tip], :note],
			[["@"], :include],
			[["&"], :snippet],
			[["$"], :config],
			[["%"], :ruby],
			[["."], :escape],
			[["--"], :comment],
			[[:md], :markdown],
			[[:frontcover, :titlepage, :halftitlepage, :frontmatter, :bodymatter, :backmatter, :backcover], :div]]
		total = 0
		macros.each { |v| total+=1; Glyph::MACROS[v.to_sym].should_not == nil }
		check_aliases = lambda do |arr, target|
			arr.each {|v| total += 1; Glyph::MACROS[v.to_sym].should == Glyph::MACROS[target.to_sym]}
		end
		aliases.each { |v| check_aliases.call v[0], v[1] }
		check_aliases.call cfg('structure.frontmatter'), :div
		check_aliases.call cfg('structure.bodymatter'), :div
		check_aliases.call cfg('structure.backmatter'), :div
		cfg('structure.frontmatter').length.should == 8
		cfg('structure.bodymatter').length.should == 4
		cfg('structure.backmatter').length.should == 12
		total.should == (Glyph::MACROS.length - 4) # test, ref, -> and em (test-only)
	end

end
