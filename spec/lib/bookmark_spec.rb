# encoding: utf-8

#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Bookmark do

	before do
		@b = Glyph::Bookmark.new :id => :test, :file => "test.glyph"
	end

	it "must be initialized with at least an id" do
		lambda { Glyph::Bookmark.new }.should raise_error
		lambda { Glyph::Bookmark.new({:id => :test}) }.should_not raise_error
		lambda { Glyph::Bookmark.new({:file => "test"}) }.should raise_error
		lambda { Glyph::Bookmark.new({:id => "test", :file => "test.glyph"}) }.should_not raise_error
	end

	it "should expose: code, file, type, and title" do
		@b.code.should == :test
		@b.type.should == :anchor
		@b.file.should == :"test.glyph"
	end

	it "should expose methods to check the bookmark type" do
		@b.respond_to?(:anchor?).should == true
		@b.respond_to?(:header?).should == true
		@b.respond_to?(:figure?).should == true
		@b.respond_to?(:indexterm?).should == true
		@b.anchor?.should == true
		@b.header?.should == false
	end

	it "should format the link for a single output file" do
		@b.link.should == "#test_glyph___test"
	end

	it "should format the link for multiple output files" do
		Glyph['document.output'] = 'web'
		b = Glyph::Bookmark.new :id => :test, :file => "test.glyph"
		b.link.should == "test.glyph#test"
		reset_quiet
	end

	it "should format the ref for a single output file" do
		@b.ref.should == "test_glyph___test"
	end

	it "should format the ref for multiple output files" do
		Glyph['document.output'] = 'web'
		b = Glyph::Bookmark.new :id => :test, :file => "test.glyph"
		b.ref.should == "test"
		reset_quiet
	end

	it "should check ID validity" do
		lambda { Glyph::Bookmark.new :id => "#test$", :file => "test.glyph"}.should raise_error(RuntimeError, "Invalid bookmark ID: #test$")		
	end

	it "should check bookmark equality" do
		@b.should == Glyph::Bookmark.new(:id => :test, :file => 'test.glyph')
		@b.should == Glyph::Bookmark.new(:id => :test, :file => :"test.glyph")
		@b.should == Glyph::Bookmark.new(:id => :test, :file => 'test.glyph', :type => :header)
		@b.should_not == Glyph::Bookmark.new(:id => :test1, :file => 'test.glyph')
		@b.should_not == Glyph::Bookmark.new(:id => :test, :file => 'test1.glyph')
	end

end

describe Glyph::BookmarkCollection do

	before do
		@b = Glyph::Bookmark.new :id => :test, :file => "test.glyph"
		@c = Glyph::BookmarkCollection.new
		@c << @b
	end

	it "should not add duplicate bookmarks" do
		lambda { @c << @b }.should raise_error(RuntimeError, "Bookmark '#{@b.ref}' already defined")
		b1 = Glyph::Bookmark.new :id => :test, :file => "introduction.glyph"
		b2 = Glyph::Bookmark.new :id => :test2, :file => "test.glyph"
		b3 = Glyph::Bookmark.new :id => :test, :file => "test.glyph", :type => :header
		lambda { @c << b1 }.should_not raise_error
		lambda { @c << b2 }.should_not raise_error
		lambda { @c << b3 }.should raise_error
		@c.should == Glyph::BookmarkCollection.new([@b, b1, b2])
	end

	it "should retrieve bookmarks by file and ID" do
		@c.get("test", "test.glyph").should == @b 
		@c.get("test", "test1.glyph").should == nil
	end
end
