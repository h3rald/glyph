# encoding: utf-8

#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Document do

	before do
		Glyph.macro :test do |node|
			"Test: #{node[:value]}"
		end
		create_tree = lambda {|text| }
		create_doc = lambda {|tree| }
		@tree = create_tree "test[test[test[Test\\|\\]...]]]"
		@doc = create_doc @tree

	end

	it "should expose document data" do
		@doc.bookmarks.should == {}
		@doc.placeholders.should == {}
		@doc.new?.should == true
	end

	it "should store bookmarks" do
		lambda { @doc.bookmark(:id => "test", :title => "Test Bookmark #1")}.should_not raise_error
		lambda { @doc.bookmark(:id => :test, :title => "Test Bookmark #2")}.should_not raise_error
		@doc.bookmarks.length.should == 1
		@doc.bookmarks[:test].should == {:id => :test, :title => "Test Bookmark #2"}
	end

	it "should store placeholders" do
		p = lambda { "test" }
		lambda { @doc.placeholder &p }.should_not raise_error
		@doc.placeholders["‡‡‡‡‡PLACEHOLDER¤1‡‡‡‡‡".to_sym].should == p
	end

	it "can inherit data from another document" do
		@doc.bookmark :id => :test1, :title => "Test #1"
		@doc.bookmark :id => :test2, :title => "Test #2"
		@doc.placeholder { "test" }
		@doc.header :id => :test3, :title => "Test #3", :level => 3
		doc2 = create_doc @tree
		doc2.bookmarks.length.should == 0
		doc2.placeholders.length.should == 0
		doc2.bookmark :id => :test4, :title => "Test #4"
		doc2.inherit_from @doc
		doc2.bookmarks.length.should == 2
		doc2.placeholders.length.should == 1
		doc2.headers.length.should == 1
		doc2.bookmarks[:test3].should == nil
	end

	it "should analyze the syntax tree and finalize the document" do
		lambda { @doc.output }.should raise_error
		lambda { @doc.finalize }.should raise_error
		lambda { @doc.analyze }.should_not raise_error
		lambda { @doc.analyze }.should raise_error
		@doc.analyzed?.should == true
		lambda { @doc.output }.should raise_error
		lambda { @doc.finalize }.should_not raise_error
		@doc.output.should == "Test: Test: Test: Test|]..."
	end

	it "should expose document structure" do
		lambda { @doc.structure }.should raise_error
		@doc.analyze
		@doc.structure.is_a?(Node).should == true
	end

	it "should substitute placeholders when finalizing" do
		Glyph.macro :count_tests do
			n = placeholder do |document|
				count = 0
				document.structure.descend do |node, level|
					count +=1 if node[:macro] == :test
				end
				count
			end
			n
		end
		text = %{
		Total: count_tests[] tests.
		test[
			test[
				test[
					test
				]
			]
			test[test]
		]
		}
		tree = create_tree text
		doc = create_doc tree
		doc.analyze
		doc.finalize
		doc.output.gsub(/\n|\t/, '')[0..14].should == "Total: 4 tests."
	end


end

