# encoding: utf-8

#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Bookmark do

	before do
		@b = Glyph::Bookmark.new :id => :test, :file => "test.glyph"
	end

	it "should be initialized with at least an id" do
		lambda { Glyph::Bookmark.new }.should raise_error
		lambda { Glyph::Bookmark.new({:id => :test}) }.should_not raise_error
		lambda { Glyph::Bookmark.new({:file => "test"}) }.should raise_error
		lambda { Glyph::Bookmark.new({:id => "test", :file => "test.glyph"}) }.should_not raise_error
	end

	it "shiuld expose title, code and file" do
		@b.file.should == "test.glyph"
		@b.code.should == :test
		@b.title.should == nil
		Glyph::Bookmark.new(:id => :test2, :title => "Test 2").title.should == "Test 2"
	end

	it "should convert to a string" do
		@b.code.to_s == @b.to_s
		"#{@b}".should == @b.to_s
	end

	it "should format the link for a single output file" do
		# Link within the same file
		@b.link.should == "#test"
		# Link to a different file file
		@b.link('intro.glyph').should == "#test"
	end

	it "should format the link for multiple output files" do
		out = Glyph['document.output']
		Glyph['document.output'] = 'web'
		# Link within the same file
		@b.link("test.glyph").should == "#test"
		# Link to a different file file
		@b.link("intro.glyph").should == "/test.html#test"
		# Test that base directory is added correctly
		Glyph["output.#{Glyph['document.output']}.base"] = ""
		@b.link("intro.glyph").should == "test.html#test"
		@b.link("test.glyph").should == "#test"
		Glyph['document.output'] = out
	end

	it "should check ID validity" do
		lambda { Glyph::Bookmark.new :id => "#test$", :file => "test.glyph"}.should raise_error(RuntimeError, "Invalid bookmark ID: #test$")		
	end

	it "should check bookmark equality" do
		@b.should == Glyph::Bookmark.new(:id => :test, :file => 'test.glyph')
		@b.should == Glyph::Bookmark.new(:id => :test, :file => "test.glyph")
		@b.should == Glyph::Bookmark.new(:id => :test, :file => 'test.glyph', :level => 2)
		@b.should_not == Glyph::Bookmark.new(:id => :test1, :file => 'test.glyph')
		@b.should_not == Glyph::Bookmark.new(:id => :test, :file => 'test1.glyph')
	end

end
