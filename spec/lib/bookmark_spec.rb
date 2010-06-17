# encoding: utf-8

#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Bookmark do

	before do
		@b = Glyph::Bookmark.new :id => :test, :file => "test.glyph"
	end

	it "must be initialized with at least id and file" do
		lambda { Glyph::Bookmark.new }.should raise_error
		lambda { Glyph::Bookmark.new({:id => :test}) }.should raise_error
		lambda { Glyph::Bookmark.new({:file => "test"}) }.should raise_error
		lambda { Glyph::Bookmark.new({:id => "test", :file => "test.glyph"}) }.should_not raise_error
	end

	it "should expose: code, path, type, and title" do
		@b.id.should == :test
		@b.type.should == :anchor
		@b.file.should == "test.glyph"
	end

	it "should expose methods to check the bookmark type" do
		@b.respond_to?(:anchor?).should == true
		@b.respond_to?(:header?).should == true
		@b.respond_to?(:figure?).should == true
		@b.respond_to?(:indexterm?).should == true
		@b.anchor?.should == true
		@b.header?.should == false
	end

	it "should format the reference for a single output file" do
		@b.ref.should == "test_glyph___test"
	end

	it "should format the reference for multiple output files" do
		Glyph['document.output'] = 'web'
		b = Glyph::Bookmark.new :id => :test, :file => "test.glyph"
		b.ref.should == "test.glyph#test"
		reset_quiet
	end

	it "should check ID validity" do
		lambda { Glyph::Bookmark.new :id => "#test$", :file => "test.glyph"}.should raise_error(RuntimeError, "Invalid bookmark ID: #test$")		
	end

	it "should expose a check method to check bookmark attributes" do
		@b.check(:id => :test).should == @b
		@b.check(:id => :test, :file => 'test.glyph').should == @b
		@b.check(:id => :test, :file => 'test1.glyph').should == nil
		@b.check(:type => :anchor, :file => 'test.glyph').should == @b
		@b.check(:type => :anchor, :file => 'test.glyph', :id => :test, :undefined => true).should == nil
	end

end
