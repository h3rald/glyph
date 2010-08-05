# encoding: utf-8

#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Analyzer do

	before do
		reset_quiet
		create_project_dir
		create_project
		Glyph.file_copy Glyph::SPEC_DIR/'files/document_for_stats.glyph', Glyph::PROJECT/'document.glyph'
		Glyph.file_copy Glyph::SPEC_DIR/'files/references.glyph', Glyph::PROJECT/'text/references.glyph'
		Glyph.run! 'generate:document'
		@a = Glyph::Analyzer.new
	end

	after do
		delete_project_dir
	end

	it "should be initialized with a document" do
		lambda { Glyph::Analyzer.new(Glyph.document) }.should_not raise_error
		lambda { Glyph::Analyzer.new }.should_not raise_error
	end

	it "should expose a macro node iterator" do
		lambda { @a.with_macros }.should raise_error(ArgumentError, "No block given")
		count = 0
		lambda { @a.with_macros {|n| count+=1} }.should_not raise_error
		count.should == 19
		count = 0
		lambda { @a.with_macros(:snippet) {|n| count+=1} }.should_not raise_error
		count.should == 2
		#count = 0
		#lambda { @a.with_macros(:&) {|n| count+=1} }.should_not raise_error
		#count.should == 2
	end

	it "should access macro instance arrays by definition" do
		@a.macro_array_for(:snippet).should == []
		@a.with_macros {}
		@a.macro_array_for(:snippet).length.should == 2
		@a.macro_array_for(:&).length.should == 2
		@a.macro_array_for(:section).length.should == 4
	end

	it "should calculate macro stats" do
		lambda {@a.stats_for :macros}.should_not raise_error
		@a.stats[:macros].blank?.should == false
		c = @a.stats[:macros]
		c[:definitions].should == Glyph::ALIASES[:by_def].keys.sort
		c[:aliases].should == Glyph::ALIASES[:by_alias].keys.sort
		c[:instances].length.should == 19
		c[:used_definitions].should == [:anchor, :include, :link, :markdown, 
			:section, :snippet, :"snippet:", :textile, :toc]
	end






end
